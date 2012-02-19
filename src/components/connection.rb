include Java

import java.awt.geom.Line2D
import java.awt.Color
import java.awt.BasicStroke

# Author::    Stanislav Chren (mailto:stanislavch@gmail.com)
# Copyright:: Copyright (c) 2012
# License::   GPL-3.0
#
# This class represents model's connection. It is a composite object which consist of two endpoints and label
class Connection

  attr_accessor :source_ep,    # source endpoint
                :target_ep,    # target endpoint
                :name,
                :definition,
                :color,        # color which is used for painting connection line and endpoints
                :stroke,       # used to change thickness of paint
                :label         # label with connection's name

  def initialize source, target, name, definition
    @source_ep = source
    @target_ep = target
    @name  = name
    @definition = definition



    @color = Color::black
    @stroke = BasicStroke.new 1
  end

  # Returns line between two endpoints
  def get_line
    source_point = @source_ep.get_anchor_point
    target_point = @target_ep.get_anchor_point

    return Line2D::Double.new source_point, target_point
  end

  # Sets label position so that it is located on the middle of the line
  def reset_label_position
    source_point = @source_ep.get_anchor_point
    target_point = @target_ep.get_anchor_point

    result_x =  (source_point.get_x + target_point.get_x) / 2
    result_y =  ((source_point.get_y + target_point.get_y) / 2 ) - 3

    @label.set_location result_x, result_y

  end
end

