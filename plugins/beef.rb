# encoding: utf-8

require 'beef/remote'

module Msf
  
  #Constants
  BeefVer = "0.1"
  
  class Plugin::Beef < Msf::Plugin
    
    class ConsoleCommandDispatcher
      include Msf::Ui::Console::CommandDispatcher
      
      def name
        "Beef"
      end
      
      def commands
        {
          "beef_connect" => "Connect to a remote BeEF server: beef_connect <beef url> <username> <password>",
          "beef_disconnect" => "Disconnect from the remote BeEF server",
          "beef_help" => "Get help on all commands",
          "beef_import" => "Import available hooked browsers into metasploit",
          "beef_online" => "List available hooked browsers",
          "beef_offline" => "List previously hooked browsers",
          "beef_review" => "Review a previously hooked browser",
          "beef_target" => "Target a currently hooked browser",
        }
      end
      
      @@beef_review_opts = Rex::Parser::Arguments.new(
        "-h" => [ false, "Help."],
        "-i" => [ true, "Display info about the offline hooked browser. \"beef_review -i <id>\""],
        "-r" => [ true, "Review the response from a previously executed command module. \"beef_review -r <id> (<command id>)\""])
        
      @@beef_target_opts = Rex::Parser::Arguments.new(
        "-h" => [ false, "Help."],
        "-i" => [ true, "Display info about the online hooked browser (target). \"beef_target -i <id>\""],
        "-r" => [ true, "Review the response from a previously executed command module. \"beef_target -r <id> (<command id>)\""],
        "-c" => [ true, "List available commands for a particular target. \"beef_target -c <id> (<command id>)\""],
        "-e" => [ true, "Execute a module against a target. \"beef_target -e <id> <command id>\""])
      
      #Thank you Nessus plugin for this!
      def beef_verify_db
				if ! (framework.db and framework.db.active)
					print_error("No database has been configured, please use db_create/db_connect first")
					return false
				end
				true
			end
			
			def beef_logo_to_os(logo)
			  case logo
        when "mac.png"
          hbos = "Mac OS X"
        when "linux.png"
          hbos = "Linux"
        when "win.png"
          hbos = "Microsoft Windows"
        when "unknown.png"
          hbos = "Unknown"
        end
		  end
      
      def cmd_beef_connect(*args)
        if (args[0] == nil or args[0] == "-h" or args[0] == "--help")
          cmd_beef_connect_help
          return
        end
        
        if args.length != 3
          cmd_beef_connect_help
          return
        end
        
        @remotebeef = BeEF::Remote::Base.new if not defined? @remotebeef
        
        if not @remotebeef.session.connected.nil?
          print_status("You are already connected")
          return
        end
        
        if (@remotebeef.session.authenticate(args[0], args[1],args[2]).nil?)
          #For some reason, the first attempt always fails, lets sleep for a couple of secs and try again
          select(nil,nil,nil,2)
          if (@remotebeef.session.authenticate(args[0], args[1], args[2]).nil?)
            print_status("Connection failed..")
          else
            print_status("Connected to "+args[0])
          end
        else
          print_status("Connected to "+args[0])
        end
      end
      
      def cmd_beef_connect_help
        print_status("  Usage: beef_connect <beef url> <username> <password>")
        print_status("Examples:")
        print_status("  beef_connect http://127.0.0.1:3000 beef beef")
      end
      
      def cmd_beef_disconnect(*args)
        if args[0] == "-h"
          cmd_beef_disconnect_help
          return
        end
        
        begin
          if @remotebeef.session.connected.nil? 
            print_status("You aren't connected")
          else
            @remotebeef.session.disconnect
            print_status("You are now disconnected")
          end
        rescue
          print_status("You aren't connected")
        end
      end
      
      def cmd_beef_disconnect_help
        print_status("Disconnect from the remote BeEF instance")
      end
      
      def cmd_beef_help(*args)
        tbl = Rex::Text::Table.new(
          'Columns' =>
            [
              'Command',
              'Help text'
            ])
        tbl << [ "Generic Commands",""]
        tbl << [ "-----------------", "-----------------"]
        tbl << [ "beef_connect", "Connect to a remote BeEF server."]
        tbl << [ "beef_disconnect", "Disconnect from the remote BeEF server."]
        tbl << [ "beef_help", "Display this help listing."]
        tbl << ["",""]
        tbl << [ "Hooked Browser Commands",""]
        tbl << [ "-----------------", "-----------------"]
        tbl << [ "beef_online", "List available hooked browsers and their details."]
        tbl << [ "beef_offline","List previously hooked browsers and their details."]
        tbl << [ "beef_import", "Import available hooked browsers into db_hosts."]
        tbl << [ "beef_review", "Review previously hooked browsers within BeEF."]
        tbl << [ "beef_target", "Target a currently hooked browser within BeEF."]
        puts "\n"
        puts tbl.to_s + "\n"
      end
			
      def cmd_beef_import(*args)
        if ! beef_verify_db
          return
        end
        
        if args[0] == "-h"
          cmd_beef_import_help
          return
        end
        
        hb = nil
        begin
          if @remotebeef.session.connected.nil?
            print_status("You aren't connected")
            return
          else
            hb = @remotebeef.zombiepoll.hooked
          end
        rescue
          print_status("You don't appear to be connected")
          return
        end
        
        print_status("Importing hosts now...")
        
        hb['hooked-browsers']['online'].each{ |x|
          if x[1]['ip'].to_s == "127.0.0.1" 
            print_status("Can't add self to db_hosts - skipping this entry")
          else
            framework.db.find_or_create_host({:host => x[1]['ip'], :os_name => beef_logo_to_os(x[1]['os_icon'].to_s) })
            print_status("Added " + x[1]['ip'])
          end
        }
        
        print_status("Importation complete.")
        
      end
      
      def cmd_beef_import_help
        print_status("Import available hooked browsers into db_hosts.")
      end
      
      def cmd_beef_online(*args)
        hb = nil
        begin
          if @remotebeef.session.connected.nil?
            print_status("You aren't connected")
            return
          else
            hb = @remotebeef.zombiepoll.hooked
          end
        rescue
          print_status("You don't appear to be connected")
          return
        end
        
        tbl = Rex::Text::Table.new(
          'Columns' => 
            [
              'Id',
              'IP',
              'OS'
            ])
        hb['hooked-browsers']['online'].each{ |x|
          tbl << [x[0].to_s , x[1]['ip'].to_s, beef_logo_to_os(x[1]['os_icon'].to_s)]
        }
        puts "\n"
        puts "Currently hooked browsers within BeEF"
        puts "\n"
        puts tbl.to_s + "\n"
      end
    
     def cmd_beef_offline(*args)
        hb = nil
        begin
          if @remotebeef.session.connected.nil?
            print_status("You aren't connected")
            return
          else
            hb = @remotebeef.zombiepoll.hooked
          end
        rescue
          print_status("You don't appear to be connected")
          return
        end
        
        tbl = Rex::Text::Table.new(
          'Columns' => 
            [
              'Id',
              'IP',
              'OS'
            ])
        hb['hooked-browsers']['offline'].each{ |x|
          tbl << [x[0].to_s , x[1]['ip'].to_s, beef_logo_to_os(x[1]['os_icon'].to_s)]
        }
        puts "\n"
        puts "Previously hooked browsers within BeEF"
        puts "\n"
        puts tbl.to_s + "\n"
      end
      
      def cmd_beef_target(*args)
        if (args[0] == nil or args[0] == "-h")
          print_status("Listing online browsers...")
          cmd_beef_online
          cmd_beef_target_help
          return
        end
        
        if @remotebeef.session.connected.nil?
          print_status("You aren't connected")
          return
        end
        
        @@beef_target_opts.parse(args) {|opt, idx, val|
          case opt
          when "-i"
            if args.length < 2
              cmd_beef_target_help
              return
            end
            @remotebeef.settarget(val)
            info = @remotebeef.zombiepoll.getinfo(@remotebeef.targetsession)
            info['results'].each { |x|
              x['data'].each { |k,v|
                print_line(k+ " - "+v)
              }
            }
            return
          when "-r"
            if args.length < 2
              cmd_beef_target_help
              return
            end
            
            if args[2].nil?
              @remotebeef.settarget(val)
              cmds = @remotebeef.command.getcommands(@remotebeef.targetsession)
              tbl = Rex::Text::Table.new(
                'Columns' =>
                  ['Command Id',
                    'Command',
                    'Execute Count'
                  ])
              cmds.each{ |x|
                x['children'].each { |y|
                  tbl << [y['id'].to_s,
                          x['text'].sub(/\W\(\d.*/,"")+"/"+y['text'].gsub(/[-\(\)]/,"").gsub(/\W+/,"_"),
                          @remotebeef.command.getcmdexeccount(@remotebeef.targetsession,y['id'])] if @remotebeef.command.getcmdexeccount(@remotebeef.targetsession,y['id']) > 0
                }
              }
              puts "\n"
              puts "List of previous command modules for this target\n"
              puts tbl.to_s + "\n"
              return
            else
              @remotebeef.settarget(args[1])
              @remotebeef.command.setmodule(args[2])
                tbl = Rex::Text::Table.new(
                  'Columns' =>
                    [
                      'Response Id',
                      'Executed Time',
                      'Response'
                    ])
              @remotebeef.command.getcmdresponses(@remotebeef.targetsession)['commands'].each do |resp|
                indiresp = @remotebeef.command.getindividualresponse(resp['object_id'])
                respout = ""
                if indiresp['results'].length == 0 or indiresp == nil
                  respout = "No response yet"
                  respdata = ""
                else
                  respout = Time.at(indiresp['results'][0]['date'].to_i).to_s
                  respdata = indiresp['results'][0]['data']['data'].to_s
                end
                tbl << [resp['object_id'].to_s,resp['creationdate'],respout]
                tbl << [respdata,"",""]
              end
              puts "\n"
              puts "List of responses for this command module\n"
              puts tbl.to_s + "\n"
              return
            end
          when "-c"
            if args[2].nil?
              @remotebeef.settarget(args[1])
              cmds = @remotebeef.command.getcommands(@remotebeef.targetsession)
              tbl = Rex::Text::Table.new(
                'Columns' =>
                  [
                    'Id',
                    'Command',
                    'Execute Count'
                  ])
              cmds.each{ |x|
                x['children'].each{ |y|
                  tbl << [y['id'].to_s, x['text'].sub(/\W\(\d.*/,"")+"/"+y['text'].gsub(/[-\(\)]/,"").gsub(/\W+/,"_"),@remotebeef.command.getcmdexeccount(@remotebeef.targetsession,y['id'])]
                }
              }
              puts "\n"
              puts "List of command modules for this target\n"
              puts tbl.to_s + "\n"
            else
              @remotebeef.settarget(args[1])
              @remotebeef.command.setmodule(args[2])
              print_line("Module name: " + @remotebeef.command.cmd['Name'])
              print_line("Module category: " + @remotebeef.command.cmd['Category'])
              print_line("Module description: " + @remotebeef.command.cmd['Description'])
              print_line("Module parameters:")

              @remotebeef.command.cmd['Data'].each{|data|
                print_line(data['name'] + " => " + data['value'] + " # this is the " + data['ui_label'] + " parameter")
              } if not @remotebeef.command.cmd['Data'].nil?
            end
            return
          when "-e"
            if args.length < 3
              cmd_beef_target_help
              return
            else
              @remotebeef.settarget(args[1])
              @remotebeef.command.setmodule(args[2])
              if not args[3].nil?
                #Therefore we have some parameters too #xntrik TODO - fix this ?
                pstring = ""
                (3..args.length-1).each do |x|
                  pstring << args[x] << " "
                end
                pstring.chop!
              end
              @remotebeef.command.runmodule(@remotebeef.targetsession).nil? ? print_status("Command not sent") : print_status("Command sent")
              return
            end
          when "-h"
            cmd_beef_target_help
            return
          else
            cmd_beef_target_help
            return
          end
        }
      end
      
      def cmd_beef_target_help
        print_status("Use the \"target\" commands to interface with online, hooked browsers")
        print @@beef_target_opts.usage()
      end
      
      def cmd_beef_review(*args)
        if (args[0] == nil or args[0] == "-h")
          print_status("Listing offline browsers...")
          cmd_beef_offline
          cmd_beef_review_help
          return
        end
        
        if @remotebeef.session.connected.nil?
          print_status("You aren't connected")
          return
        end
        
        @@beef_review_opts.parse(args) {|opt, idx, val|
          case opt
            when "-i"
              if args.length < 2
                cmd_beef_review_help
                return
              end
              @remotebeef.setofflinetarget(val)
              info = @remotebeef.zombiepoll.getinfo(@remotebeef.targetsession)
              info['results'].each { |x|
                x['data'].each { |k,v|
                  print_line(k+ " - "+v)
                }
              }
            when "-r"
              if args.length < 2
                cmd_beef_review_help
                return
              end
              if args[2].nil?
                @remotebeef.setofflinetarget(args[1])
                cmds = @remotebeef.command.getcommands(@remotebeef.targetsession)
                tbl = Rex::Text::Table.new(
                  'Columns' =>
                    [
                      'Command Id',
                      'Command',
                      'Execute Count'
                    ])
                cmds.each{ |x|
                  x['children'].each{ |y|
                    tbl << [y['id'].to_s,
                            x['text'].sub(/\W\(\d.*/,"")+"/"+y['text'].gsub(/[-\(\)]/,"").gsub(/\W+/,"_"),
                            @remotebeef.command.getcmdexeccount(@remotebeef.targetsession,y['id'])] if @remotebeef.command.getcmdexeccount(@remotebeef.targetsession,y['id']) > 0
                  }
                }
                puts "\n"
                puts "List of previous command modules for this target\n"
                puts tbl.to_s + "\n"
                return
              else
                @remotebeef.setofflinetarget(args[1])
                @remotebeef.command.setmodule(args[2])
                tbl = Rex::Text::Table.new(
                  'Columns' =>
                    [
                      'Response Id',
                      'Executed Time',
                      'Response'
                    ])
                @remotebeef.command.getcmdresponses(@remotebeef.targetsession)['commands'].each do |resp|
                  indiresp = @remotebeef.command.getindividualresponse(resp['object_id'])
                  respout = ""
                  if indiresp['results'].length == 0 or indiresp == nil
                    respout = "No response yet"
                    respdata = ""
                  else
                    respout = Time.at(indiresp['results'][0]['date'].to_i).to_s
                    respdata = indiresp['results'][0]['data']['data'].to_s
                  end
                  tbl << [resp['object_id'].to_s,resp['creationdate'],respout]
                  tbl << [respdata,"",""]
                end
              end
              puts "\n"
              puts "List of responses for this command module\n"
              puts tbl.to_s + "\n"
              return
            when "-h"
              cmd_beef_review_help
              return
            else
              cmd_beef_review_help
              return
          end
        }
      end
      
      def cmd_beef_review_help
        print_status("Use the \"review\" commands to review previously hooked browsers, and commands executed against them")
        print @@beef_review_opts.usage()
      end
    end
    
    def initialize(framework, opts)
      
      super
      
      add_console_dispatcher(ConsoleCommandDispatcher)
      print_status("BeEF Bridge for Metasploit #{BeefVer}")
      print_good("Type %bldbeef_help%clr for a command listing")
    end
    
    def cleanup
      remove_console_dispatcher('Beef')
    end
    
    def name
      "beef"
    end
    
    def desc
      "BeEF Bridge for Metasploit #{BeefVer}"
    end
    protected
  end
end
