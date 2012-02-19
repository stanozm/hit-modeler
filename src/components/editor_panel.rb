include Java

import javax.swing.JPanel

# Author::    Stanislav Chren (mailto:stanislavch@gmail.com)
# Copyright:: Copyright (c) 2012
# License::   GPL-3.0
#
# This class represents panel on which whole model is drawn. It is also responsible for drawing lines between endpoints
# of the same connection
class EditorPanel < JPanel
  attr_accessor :parent_frame

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

     @parent_frame.connections.each do |c|
       g.set_color c.color
       g.set_stroke c.stroke
       g.draw(c.get_line)

     end

     g.set_color Color::black
     g.set_stroke BasicStroke.new 1
  end


end