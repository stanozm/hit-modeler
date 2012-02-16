include Java

require "components/endpoint.rb"

import java.awt.geom.Line2D
import java.awt.Color
import java.awt.BasicStroke

class Connection

  attr_accessor :sourceEP, :targetEP, :name, :definition, :color, :stroke, :label

  def initialize source, target, name, definition
    @sourceEP = source
    @targetEP = target
    @name  = name
    @definition = definition



    @color = Color::black
    @stroke = BasicStroke.new 1
  end

  def get_line
    sourcePoint = @sourceEP.get_anchor_point
    targetPoint = @targetEP.get_anchor_point

    return Line2D::Double.new sourcePoint, targetPoint
  end

  def reset_label_position
    sourcePoint = @sourceEP.get_anchor_point
    targetPoint = @targetEP.get_anchor_point

    resultX =  (sourcePoint.get_x + targetPoint.get_x) / 2
    resultY =  ((sourcePoint.get_y + targetPoint.get_y) / 2 ) - 3

    @label.set_location resultX, resultY

  end
end

