class TreeEvents
  def initialize
    @listeners = {}
  end
  
  def on(event, &block)
    @listeners[event] ||= []
    @listeners[event] << block
  end
  
  def emit(event, *args)
    @listeners[event]&.each { |block| block.call(*args) }
  end
  
  def clear(event = nil)
    if event
      @listeners[event] = []
    else
      @listeners.clear
    end
  end
  
  def has_listeners?(event)
    @listeners[event]&.any?
  end
end 