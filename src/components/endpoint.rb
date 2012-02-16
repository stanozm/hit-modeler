include Java

import javax.swing.JLabel
import java.awt.RenderingHints
import java.awt.geom.Line2D
import java.awt.geom.Ellipse2D
import java.lang.Math
import java.awt.geom.Point2D

class Endpoint < JLabel

  attr_accessor :type,          #  "0m", "1m", "01", "11"
                :direction,     #  "up", "down", "right", "left"
                :entityParent,
                :connection,
                :offset

  ENTITY_WIDTH = 110
  ENTITY_HEIGHT = 60

  def initialize
    super

    @direction = "left"
    @offset = 0
  end

  def paintComponent g

    rh = RenderingHints.new RenderingHints::KEY_ANTIALIASING,
                            RenderingHints::VALUE_ANTIALIAS_ON

    rh.put RenderingHints::KEY_RENDERING,
           RenderingHints::VALUE_RENDER_QUALITY

    g.setRenderingHints rh

    g.set_color connection.color
    g.set_stroke connection.stroke

    paint_endpoint g, @type, @direction

  end

  #TODO Later should be reworked into relative positions
  def paint_endpoint g, type, direction

    parts = []
    rotationAngle = 0


    case type
      when "0m"
        parts << (Line2D::Double.new 0, 8, 5, 8)
        parts << (Ellipse2D::Double.new 5, 5, 6, 6)
        parts << (Line2D::Double.new 11, 8, 16, 0)
        parts << (Line2D::Double.new 11, 8, 16, 8)
        parts << (Line2D::Double.new 11, 8, 16, 16)
      when "1m"
        parts << (Line2D::Double.new 0, 8, 11, 8)
        parts << (Line2D::Double.new 9, 4, 9, 12)
        parts << (Line2D::Double.new 11, 8, 16, 0)
        parts << (Line2D::Double.new 11, 8, 16, 8)
        parts << (Line2D::Double.new 11, 8, 16, 16)
      when "01"
        parts << (Line2D::Double.new 0, 8, 5, 8)
        parts << (Ellipse2D::Double.new 5, 5, 6, 6)
        parts << (Line2D::Double.new 11, 8, 16, 8)
        parts << (Line2D::Double.new 12, 5, 12, 11)
      when "11"
        parts << (Line2D::Double.new 0, 8, 16, 8)
        parts << (Line2D::Double.new 12, 5, 12, 11)
        parts << (Line2D::Double.new 8, 5, 8, 11)
    end

    case direction
      when "left"
        rotationAngle = 0
      when "up"
        rotationAngle = Math.to_radians 90
      when "down"
        rotationAngle = Math.to_radians -90
      when "right"
        rotationAngle = Math.to_radians 180
    end

    g.rotate rotationAngle, 8, 8
    parts.each { |p| g.draw p  }
  end

  #returns Point2D instance of anchor point. It should be used by connection to determine its line position
  def get_anchor_point
    x = self.get_x
    y = self.get_y

    anchorX, anchorY = x, y

    case @direction
      when "left"
        anchorY = y+8
      when "up"
        anchorX = x+8
      when "down"
        anchorX = x+8
        anchorY = y+16
      when "right"
        anchorX = x+16
        anchorY = y+8
    end
    return Point2D::Double.new anchorX, anchorY
  end

  #Computes and sets own direction based on its parent entity.
  #Also sets proper offset based on current position, direction and parent position
  def reset_direction
    myX = self.get_x
    myY = self.get_y

    #if there is no current parent, set default direction to "left"
    if !@entityParent.nil?
      parentX = @entityParent.get_x
      parentY = @entityParent.get_y
    else
      @direction = "left"
      return @direction
    end

    if myX + 16 >= parentX + ENTITY_WIDTH
        @direction = "right"
    end

    if myX  <= parentX
        @direction = "left"
    end

    if myY + 16 >= parentY + ENTITY_HEIGHT
       @direction = "down"
    end

    if myY  <= parentY
      @direction = "up"
    end



    #Now sets offset based on direction. If endpoint is out of bounds, it sets offest to the edge
    case @direction
      when "up", "down"
        if myX +16 > parentX + ENTITY_WIDTH
          @offset = ENTITY_WIDTH - 16
        else if myX < parentX
               @offset = 0
             else
               @offset = myX - parentX
             end
        end
      when "right", "left"
        if myY + 16 > parentY + ENTITY_HEIGHT
          @offset = ENTITY_HEIGHT - 16
        else if myY < parentY
              @offset = 0
             else
              @offset = myY - parentY
             end
        end
    end

  end

  def reset_position
    parentX = @entityParent.get_x
    parentY = @entityParent.get_y

    case @direction
      when "up"
        self.set_location parentX + @offset, parentY - 16
      when "down"
        self.set_location parentX + @offset, parentY + ENTITY_HEIGHT
      when "left"
        self.set_location parentX - 16, parentY + @offset
      when "right"
        self.set_location parentX + ENTITY_WIDTH, parentY + @offset
    end

  end

end