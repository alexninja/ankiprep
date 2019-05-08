class Progress
  def initialize(total=0)
    @total = total
    @step = (total/40).to_i + 1
    @start = Time.now
    @curr = 0
    @str = ""
    yield self
    done
  end
  def tick
    return if @total == 0
    @curr += 1
    return unless @curr % @step == 0
    format
  end
private
  def format
    clear
    @str = "#{(100.to_f * @curr / @total).to_i}%"
    print @str
  end
  def clear
    @str.size.times { print 8.chr }
  end
  def done
    clear
    puts Kernel.format("%.2f s", Time.now - @start)
  end
end
