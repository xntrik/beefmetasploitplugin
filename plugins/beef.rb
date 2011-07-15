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
          "beef_help" => "Get help on all commands"
        }
      end
      
      def cmd_beef_connect(*args)
        if (args[0] == nil or args[0] == "-h" or args[0] == "--help")
          print_status("  Usage: beef_connect <beef url> <username> <password>")
          print_status("Examples:")
          print_status("  beef_connect http://127.0.0.1:3000 beef beef")
          return
        end
        
        @remotebeef = BeEF::Remote::Base.new if not defined? @remotebeef
        
        #This is not working yet
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