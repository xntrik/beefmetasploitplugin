module BeEF
module Remote
  
  class Base
    attr_accessor :session
    attr_accessor :zombiepoll
    attr_accessor :command
    attr_accessor :jobs
    attr_reader :targetsession
    attr_reader :target
    attr_reader :targetip
    
    def initialize()
      self.session = BeEF::Remote::Session.new
      self.zombiepoll = BeEF::Remote::ZombiePoll.new(self.session)
      self.command = BeEF::Remote::Command.new(self.session)
      self.jobs = Rex::JobContainer.new
    end
    
    def settarget(id)
      self.targetsession = self.zombiepoll.getsession(id)
      self.targetip = self.zombiepoll.getip(id)
      self.target = id
    end
    
    def setofflinetarget(id)
      self.targetsession = self.zombiepoll.getofflinesession(id)
      self.targetip = "(OFFLINE) " + self.zombiepoll.getofflineip(id)
      self.target = id
    end
    
    def cleartarget
      self.targetsession = nil
      self.target = nil
      self.targetip = nil
    end
    
    protected
    
    attr_writer :target
    attr_writer :targetsession
    attr_writer :targetip
    attr_writer :command
  end
  
end end