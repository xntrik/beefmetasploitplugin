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
          "beef_test" => "Testing adding a host"
        }
      end
      
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
		  
      #TODO: DELETE ME
      def cmd_beef_test(*args)
        framework.db.find_or_create_host({:host => "192.168.1.1",:os_name => "Mac OS X"})
      end
      
      def cmd_beef_connect(*args)
        if (args[0] == nil or args[0] == "-h" or args[0] == "--help")
          print_status("  Usage: beef_connect <beef url> <username> <password>")
          print_status("Examples:")
          print_status("  beef_connect http://127.0.0.1:3000 beef beef")
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
      
      def cmd_beef_disconnect(*args)
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
      
      def cmd_beef_help(*args)
        tbl = Rex::Ui::Text::Table.new(
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
        tbl << [ "beef_import", "Import available hooked browsers into db_hosts."]
        puts "\n"
        puts tbl.to_s + "\n"
      end
			
      def cmd_beef_import(*args)
        if ! beef_verify_db
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
        
        hb['hooked-browsers']['online'].each { |x|
          framework.db.find_or_create_host({:host => x[1]['ip'].to_s ,:os_name => beef_logo_to_os(x[1]['os_icon'].to_s).to_s })
          print_status("Added " + x[1]['ip'])
        }
        
        print_status("Importation complete.")
        
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
        
        tbl = Rex::Ui::Text::Table.new(
          'Columns' => 
            [
              'Id',
              'IP',
              'OS'
            ])
        hb['hooked-browsers']['online'].each{ |x|
          tbl << [x[0].to_s , beef_logo_to_os(x[1]['os_icon'].to_s) , x[1]['ip'].to_s]
        }
        puts "Currently hooked browsers within BeEF"
        puts "\n"
        puts tbl.to_s + "\n"
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