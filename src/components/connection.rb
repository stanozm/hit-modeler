include Java

require "components/endpoint.rb"

import java.awt.geom.Line2D
import java.awt.Color
import java.awt.BasicStroke

class Connection

  attr_accessor :source_ep, :target_ep, :name, :definition, :color, :stroke, :label

  def initialize source, target, name, definition
    @source_ep = source
    @target_ep = target
    @name  = name
    @definition = definition



    @color = Color::black
    @stroke = BasicStroke.new 1
  end

  def get_line
    source_point = @source_ep.get_anchor_point
    target_point = @target_ep.get_anchor_point

    return Line2D::Double.new source_point, target_point
  end

  def reset_label_position
    source_point = @source_ep.get_anchor_point
    target_point = @target_ep.get_anchor_point

    result_x =  (source_point.get_x + target_point.get_x) / 2
    result_y =  ((source_point.get_y + target_point.get_y) / 2 ) - 3

    @label.set_location result_x, result_y

  end
end

