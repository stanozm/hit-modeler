include Java

require "components/endpoint.rb"

import java.awt.geom.Line2D


class Connection

  attr_accessor :sourceEP, :targetEP, :name, :definition

  def initialize source, target, name, definition
    @sourceEP = source
    @targetEP = target
    @name  = name
    @definition = definition
  end

  def get_line
    sourcePoint = @sourceEP.get_anchor_point
    targetPoint = @targetEP.get_anchor_point

    return Line2D::Double.new sourcePoint, targetPoint
  end
end

