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
          "beef_connect" => "Connect to a remote BeEF server: beef_connect username:password@hostname:port",
          "beef_help" => "Get help on all commands"
        }
      end
      
      def cmd_beef_connect
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