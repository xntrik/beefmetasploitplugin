module BeEF
module Remote

class ZombiePoll
  
  #include Rex::Ui::Subscriber
  #the above should allow the standard print_status etc messages, but this isn't working pretty yet
  #Actually, the MSF framework uses a clever subscriber system, I'm just hacking this by setting a local instance of the 
  # Rex output :P

  #attr_accessor :session
  attr_reader :hb
    
  def initialize(session)
    self.session = session
  end
  
  def hooked
    self.hb = self.session.getjson("/ui/panel/hooked-browser-tree-update.json")
  end
    
  def hookedpoll(ctx)
    ctx.print_line
    ctx.print_status("Starting the online zombie poll-er")
    
    hooked
    ctx.print_status("Initial zombies:")
    
    self.hb['hooked-browsers']['online'].each{|x|
      ctx.print_line(x[0]+": "+x[1]['browser_icon']+" on "+x[1]['os_icon']+" in the domain: "+x[1]['domain']+" with the ip: "+x[1]['ip'])
    }
    
    while(true)
      oldhb = self.hb
      
      hooked
      if oldhb == self.hb
        #ctx.print_status("the same") #Perhaps print something if there's a verbose option set?
      else
        ctx.print_status("different!")
        if oldhb['hooked-browsers']['online'].length < self.hb['hooked-browsers']['online'].length #we have a NEW HB
          ctx.print_status("We got a NEW HB")
          tmp = self.hb['hooked-browsers']['online'].select{|x,y| !oldhb['hooked-browsers']['online'].include?(x)}
          tmp.each{ |x|
            ctx.print_line(x[1]['browser_icon']+" on "+x[1]['os_icon']+" in the domain: "+x[1]['domain']+" with the ip: "+x[1]['ip'])
          }
        elsif oldhb['hooked-browsers']['online'].length > self.hb['hooked-browsers']['online'].length #we have lost a HB
          ctx.print_status("We lost a HB")
          tmp = oldhb['hooked-browsers']['online'].select{|x,y| !self.hb['hooked-browsers']['online'].include?(x)}
          tmp.each{ |x|
            ctx.print_line(x[1]['browser_icon']+" on "+x[1]['os_icon']+" in the domain: "+x[1]['domain']+" with the ip: "+x[1]['ip'])
          }
        else #we lost and got a new one
          ctx.print_status("The hell? I think we lost and gained a new HB in a single poll - TODO")
        end
      end
      select(nil,nil,nil,5)
    end
  end    
  
  def getsession(id)
    if self.hb.nil?
      self.hooked
    end
    self.hb['hooked-browsers']['online'][id.to_s]['session']
  end
  
  def getofflinesession(id)
    if self.hb.nil?
      self.hooked
    end
    self.hb['hooked-browsers']['offline'][id.to_s]['session']
  end
    
  def getip(id)
    if self.hb.nil?
      self.hooked
    end
    self.hb['hooked-browsers']['online'][id.to_s]['ip']
  end
  
  def getofflineip(id)
    if self.hb.nil?
      self.hooked
    end
    self.hb['hooked-browsers']['offline'][id.to_s]['ip']
  end
  
  def getinfo(session)
    self.session.getjson("/ui/modules/select/zombie_summary.json",{"zombie_session"=>session})
  end
    
  protected
  
  attr_writer :hb
  attr_accessor :session

end

end end