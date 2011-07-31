module BeEF
module Remote

  class Command
    
    attr_reader :cmd
    
    def initialize(session)
      self.session = session
      self.cmd = {}
    end
    
    def getcommands(session)
      self.session.getjson("/ui/modules/select/commandmodules/tree.json",{"zombie_session"=>session.to_s})
    end
    
    def setmodule(id)
      tmp = self.session.getjson("/ui/modules/select/commandmodule.json",{"command_module_id"=>id.to_s})
      self.cmd['id'] = id.to_s
      self.cmd['Name'] = tmp['command_modules']['1']['Name'].to_s
      self.cmd['Description'] = tmp['command_modules']['1']['Description'].to_s
      self.cmd['Category'] = tmp['command_modules']['1']['Category'].to_s
      self.cmd['Data'] = tmp['command_modules']['1']['Data']
    end
    
    def clearmodule
      self.cmd = {}
    end
    
    def setparam(param,value)
      self.cmd['Data'].each do |data|
        if data['name'] == param
          data['value'] = value
          return
        end
      end
    end
    
    def runmodule(session)
      options = {}
      options.store("zombie_session", session.to_s)
      options.store("command_module_id", self.cmd['id'])
      options.store("nonce",self.session.nonce.to_s)
      
      if not self.cmd['Data'].nil?
        self.cmd['Data'].each do |key|
          options.store("txt_"+key['name'].to_s,key['value'])
        end
      end
      
      resp = self.session.getraw("/ui/modules/commandmodule/new", options)
      if resp.body == "{success : true}"
        ret = "true"
      else
        ret = nil
      end
      ret
    end
    
    def getcmdexeccount(session,cmdid)
      json = self.session.getjson("/ui/modules/commandmodule/commands.json", {"zombie_session"=>session.to_s,"command_module_id"=>cmdid,"nonce"=>self.session.nonce.to_s})
      json['commands'].length
    end
    
    def getcmdresponses(session)
      self.session.getjson("/ui/modules/commandmodule/commands.json",{"zombie_session"=>session.to_s,"command_module_id"=>self.cmd['id'],"nonce"=>self.session.nonce.to_s})
    end
    
    def getindividualresponse(cmdid)
      begin
        return self.session.getjson("/ui/modules/select/command_results.json",{"command_id"=>cmdid})
      rescue
        return nil
      end
    end
    
    protected
    attr_writer :cmd
    attr_accessor :session
  end

end end