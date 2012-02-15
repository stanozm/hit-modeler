include Java

import javax.swing.JPanel

class EditorPanel < JPanel
  attr_accessor :parentFrame

  def initialize
    super

  end

  def paintComponent g
     super g

     #Test if drawing works
     #TODO remove eventually
     g.draw_line 500, 500, 600, 600
  end


end