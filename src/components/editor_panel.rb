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

     @parentFrame.connections.each do |c|
       g.set_color c.color
       g.set_stroke c.stroke
       g.draw(c.get_line)

     end

     g.set_color Color::black
     g.set_stroke BasicStroke.new 1
  end


end