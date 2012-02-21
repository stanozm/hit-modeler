include Java
import java.awt.Point

require "rspec"

require File.expand_path("../src/modeler.rb", File.dirname(__FILE__))
require File.expand_path("../src/components/endpoint.rb", File.dirname(__FILE__))
require File.expand_path("../src/components/entity", File.dirname(__FILE__))


describe Modeler, "when it starts" do
  before do
    @modeler = Modeler.new
  end

  it "should have zero entities" do
    @modeler.entities.count.should == 0
  end

  it "should have zero connections" do
    @modeler.connections.count.should == 0
  end

  after do
    @modeler.dispose
  end
end

describe Modeler, "when entity is created" do
  before do
    @modeler = Modeler.new
    @modeler.add_entity "New entity", "kernel", "definition", 100, 100
  end

  it "should be added to the model" do
    @modeler.entities.count.should == 1
    entity = @modeler.entities.first
    entity.name.should == "New entity"
    entity.type.should == "kernel"
    entity.definition.should == "definition"
    entity.get_x.should == 100
    entity.get_y.should == 100
  end

  after do
    @modeler.dispose
  end
end

describe Modeler, "when connection and entity is added" do
  before do
    @modeler = Modeler.new
    @e1 = @modeler.add_entity "entity1", "kernel", "definition", 100, 100
    @e2 = @modeler.add_entity "entity2", "associative", "definition", 400, 400
    point_s = Point.new 220, 150
    point_t = Point.new 450, 380
    @con = @modeler.add_connection_specific_endpoints @e1, @e2,point_s,point_t,"0m","0m","connection","definition"
  end

  it "should be added to the model" do
    @modeler.connections.count.should == 1
    @modeler.connections.first.should == @con
  end

  it "should have correct endpoints" do
    @con.source_ep.entity_parent.should == @e1
    @con.target_ep.entity_parent.should == @e2
    @con.source_ep.direction.should == "down"
    @con.source_ep.offset.should == 94
    @con.target_ep.direction.should == "up"
    @con.target_ep.offset.should == 50
  end

  it "should have entities with proper children" do
    @e1.endpoints.first.should == @con.source_ep
    @e2.endpoints.first.should == @con.target_ep
  end

  it "should clear previous model when new one is created" do
    @modeler.clear_model
    @modeler.entities.should be_empty
    @modeler.connections.should be_empty
  end

  after do
    @modeler.dispose
    @e1 = nil
    @e2 = nil
    @con = nil
  end
end

describe Modeler do
  before do
    @modeler = Modeler.new
    @e1 = @modeler.add_entity "e1", "kernel", "definition", 100, 100
    @e2 = @modeler.add_entity "e2", "associative", "definiton", 300, 300
  end

  it "should compute proper intersection point" do
    pa = Point.new 100, 100
    pb = Point.new 100, 200
    pc = Point.new 50, 150
    pd = Point.new 150, 150
    p = @modeler.get_intersection_point pa,pb,pc,pd
    p.get_x.should == 100
    p.get_y.should == 150
  end

  it "should retrieve proper entity by given id" do
    e = @modeler.get_entity @e1.id
    e.should == @e1
  end

  it "should return proper bounding rectangle of the model" do
    rec = @modeler.get_bounding_rectangle
    rec.get_x.should == 100
    rec.get_y.should == 100
    rec.get_width.should == 310
    rec.get_height.should == 260
  end

  after do
    @modeler.dispose
    @e1 = nil
    @e2 = nil
  end
end