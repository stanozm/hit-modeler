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
                :entity_parent,
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
    rotation_angle = 0


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
        rotation_angle = 0
      when "up"
        rotation_angle = Math.to_radians 90
      when "down"
        rotation_angle = Math.to_radians -90
      when "right"
        rotation_angle = Math.to_radians 180
    end

    g.rotate rotation_angle, 8, 8
    parts.each { |p| g.draw p  }
  end

  #returns Point2D instance of anchor point. It should be used by connection to determine its line position
  def get_anchor_point
    x = self.get_x
    y = self.get_y

    anchor_x, anchor_y = x, y

    case @direction
      when "left"
        anchor_y = y+8
      when "up"
        anchor_x = x+8
      when "down"
        anchor_x = x+8
        anchor_y = y+16
      when "right"
        anchor_x = x+16
        anchor_y = y+8
    end
    return Point2D::Double.new anchor_x, anchor_y
  end

  #Computes and sets own direction based on its parent entity.
  #Also sets proper offset based on current position, direction and parent position
  def reset_direction
    myX = self.get_x
    myY = self.get_y

    #if there is no current parent, set default direction to "left"
    if !@entity_parent.nil?
      parent_x = @entity_parent.get_x
      parent_y = @entity_parent.get_y
    else
      @direction = "left"
      return @direction
    end

    if myX + 16 >= parent_x + ENTITY_WIDTH
        @direction = "right"
    end

    if myX  <= parent_x
        @direction = "left"
    end

    if myY + 16 >= parent_y + ENTITY_HEIGHT
       @direction = "down"
    end

    if myY  <= parent_y
      @direction = "up"
    end



    #Now sets offset based on direction. If endpoint is out of bounds, it sets offest to the edge
    case @direction
      when "up", "down"
        if myX +16 > parent_x + ENTITY_WIDTH
          @offset = ENTITY_WIDTH - 16
        else if myX < parent_x
               @offset = 0
             else
               @offset = myX - parent_x
             end
        end
      when "right", "left"
        if myY + 16 > parent_y + ENTITY_HEIGHT
          @offset = ENTITY_HEIGHT - 16
        else if myY < parent_y
              @offset = 0
             else
              @offset = myY - parent_y
             end
        end
    end

  end

  def reset_position
    parent_x = @entity_parent.get_x
    parent_y = @entity_parent.get_y

    case @direction
      when "up"
        self.set_location parent_x + @offset, parent_y - 16
      when "down"
        self.set_location parent_x + @offset, parent_y + ENTITY_HEIGHT
      when "left"
        self.set_location parent_x - 16, parent_y + @offset
      when "right"
        self.set_location parent_x + ENTITY_WIDTH, parent_y + @offset
    end

  end

end