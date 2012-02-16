include Java

import javax.swing.JLabel
import java.awt.Color
import java.awt.Font
import java.awt.RenderingHints

class Entity < JLabel

  attr_accessor :name, :definition, :type, :endpoints

  @name = ""
  @definition = ""
  @type = ""

  def initialize
    super

    @endpoints = []

  end

  def paintComponent g


    rh = RenderingHints.new RenderingHints::KEY_ANTIALIASING,
                            RenderingHints::VALUE_ANTIALIAS_ON

    rh.put RenderingHints::KEY_RENDERING,
           RenderingHints::VALUE_RENDER_QUALITY

    g.setRenderingHints rh

    #main rectangle
    g.setColor Color.new 0, 0, 0
    h = get_height
    w = get_width
    g.drawRect 0, 0, w-1, h-1

    #entity type
    case @type
      when "kernel"
        g.drawRect w-25, 7, 13, 13

      when "associative"
        g.drawLine w-25+(13/2), 7, w-12, 7+(13/2)
        g.drawLine w-12, 7+(13/2), w-25+(13/2), 7+13
        g.drawLine w-25+(13/2), 7+13, w-25, 7+(13/2)
        g.drawLine w-25, 7+(13/2), w-25+(13/2), 7

      when "descriptive"
        g.drawRect w-25, 7, 6, 6
        g.drawLine w-19, 10, w-16, 10
        g.drawLine w-16, 10, w-16, 16
        g.drawLine w-16, 16, w-22, 16
        g.drawLine w-22, 16, w-22, 13
    end

    #entity name
    g.setFont Font.new "Verdana", Font::BOLD, 12
    g.drawString @name, 5, (h/2)+5
  end



end