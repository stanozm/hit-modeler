include Java

import javax.swing.JPanel

class EditorPanel < JPanel
  attr_accessor :parentFrame, :connections

  def initialize
    super



  end

  def paintComponent g
     super g

     rh = RenderingHints.new RenderingHints::KEY_ANTIALIASING,
                             RenderingHints::VALUE_ANTIALIAS_ON

     rh.put RenderingHints::KEY_RENDERING,
            RenderingHints::VALUE_RENDER_QUALITY

     g.setRenderingHints rh

     @parentFrame.connections.each{ |c| g.draw(c.get_line)}
  end


end