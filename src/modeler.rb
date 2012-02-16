include Java

require 'components/entity.rb'
require 'components/entity_dialog.rb'
require 'components/endpoint.rb'
require 'components/editor_panel.rb'
require 'components/connection.rb'
require 'actions/select_action.rb'
require 'actions/delete_action.rb'
require 'actions/panel_mouse_action.rb'
require 'actions/move_action.rb'
require 'actions/endpoint_mouse_action.rb'

import java.awt.BorderLayout
import javax.swing.JPanel
import javax.swing.JFrame
import javax.swing.ImageIcon
import javax.swing.JButton
import javax.swing.JMenuBar
import javax.swing.JMenu
import javax.swing.JToolBar
import javax.swing.JComponent
import java.lang.System
import java.awt.Color
import java.awt.event.KeyEvent
import javax.swing.JMenuItem
import javax.swing.JToggleButton
import javax.swing.ButtonGroup
import java.awt.Dimension
import javax.swing.JScrollPane
import java.awt.event.MouseAdapter
import javax.swing.SwingUtilities
import javax.swing.JOptionPane
import javax.swing.BorderFactory
import javax.swing.JLabel
import javax.swing.AbstractAction
import javax.swing.KeyStroke
import java.awt.geom.Line2D
import java.awt.geom.Point2D
import java.awt.event.ComponentAdapter
java_import 'ComponentMover'

puts $CLASSPATH
class Modeler < JFrame

  attr_accessor :drawType, :entities, :connections, :cm, :focus, :entityDialog, :panel

  ENTITY_WIDTH = 110
  ENTITY_HEIGHT = 60
  ENDPOINT_WIDTH = 16
  ENDPOINT_HEIGHT = 16

  def initialize
    super "HIT Modeler"

    @entities, @connections = []
    @cm = ComponentMover.new


    self.initUI
  end

  def initUI
    @connections = []
    @entities = []


    #Menu definition
    @menubar = JMenuBar.new

    @fileMenu = JMenu.new "File"

    @itemNew = JMenuItem.new "New"
    @itemSave = JMenuItem.new "Save"
    @itemLoad = JMenuItem.new "Load"
    @itemExit = JMenuItem.new "Exit"

    @itemExit.set_tool_tip_text "Exit application"
    @itemExit.add_action_listener do |e|
      System.exit 0
    end




    [@itemNew,
     @itemSave,
     @itemLoad,
     @itemExit].each{ |c| @fileMenu.add c}

    @menubar.add @fileMenu
    self.set_jmenu_bar @menubar

    #-----------------------------------------------------------

    #Toolbar definition
    @toolbar = JToolBar.new

    #Toolbar buttons
    @pointerButton = JToggleButton.new "pointer"
    @kernelButton = JToggleButton.new "kernel"
    @assocButton = JToggleButton.new "associative"
    @descButton = JToggleButton.new "descriptive"
    @connectButton = JToggleButton.new "connection"

    #Adding buttons into button group, so that only one is selected at a time
    @group = ButtonGroup.new
    [@pointerButton,
     @kernelButton,
     @assocButton,
     @descButton,
     @connectButton].each {|c| @group.add c}

    #Default selection
    @group.set_selected(@pointerButton.get_model,true)
    @drawType = "pointer"

    #Adding button into toolbar
    #TODO replace text with icons
    [@pointerButton,
     @kernelButton,
     @assocButton,
     @descButton,
     @connectButton].each {|c| @toolbar.add c}

    #Sets drawType after switching button selection
    #and enables/disables dragging
    [@pointerButton,
     @kernelButton,
     @assocButton,
     @descButton,
     @connectButton].each {
      |c| c.add_action_listener do |e|
        @drawType = e.get_action_command

        if @drawType == "connection"
          @cm.set_dragging_enabled false
        else
          @cm.set_dragging_enabled true
        end
      end
     }

    #Adding toolbar to frame
    self.add @toolbar, BorderLayout::NORTH

    #------------------------------------------------------------


    #Panel & ScrollPane definition
    #@panel = JPanel.new
    @panel = EditorPanel.new
    @panel.parentFrame = self
    puts @panel.parentFrame.class.to_s
    @panel.set_layout nil
    @panel.set_background Color.new 255, 255, 255
    @panel.set_preferred_size Dimension.new 1024, 1024

    #Adding delete action to remove components
    stroke = KeyStroke.getKeyStroke(KeyEvent::VK_DELETE)
    inputMap = @panel.get_input_map JComponent::WHEN_IN_FOCUSED_WINDOW
    inputMap.put stroke, "DELETE"
    @panel.get_action_map.put "DELETE", DeleteAction.new

    #Adding scrollbars to JPanel
    @scrollPane = JScrollPane.new @panel
    @scrollPane.set_viewport_view @panel
    @scrollPane.get_vertical_scroll_bar.set_unit_increment 10
    self.get_content_pane.add @scrollPane

    #Registering listener for adding new components
    @panel.add_mouse_listener PanelMouseAction.new


    add_entity "assoc", "associative", nil, 200, 200
    e1 = add_entity "kernel", "kernel", nil, 50, 50
    e2 = add_entity "desc", "descriptive", "aaa", 300, 10
    #e2.add_component_listener MoveAction.new
    c1 = add_connection e1, e2, (Point2D::Double.new 50+55, 50+30), (Point2D::Double.new 300+55, 10+30), "0m", "0m", "aaa", "dd"




    #-----------------------------------------------------------

    #Frame setup
    self.set_default_close_operation JFrame::EXIT_ON_CLOSE
    self.set_size 1024, 768
    self.set_location_relative_to nil

    #TODO Remove before testing
    self.set_visible true

    #Entity property dialog setup
    @entityDialog = EntityDialog.new self, true
    @entityDialog.set_visible false


  end
    #-----------------------------------------------------------

    #Model management
    #Creates new entity with given parameters, which is then added to panel and made movable
    def add_entity(name, type, definition, x, y)

      entity = Entity.new
      entity.type = type
      entity.definition = definition
      entity.set_tool_tip_text definition

      if name.empty? || name.nil?
        name = "untitled"
      else
        entity.name = name
      end

      #TODO width a height budu konstanty
      entity.set_bounds x, y, ENTITY_WIDTH, ENTITY_HEIGHT
      @panel.add entity

      entity.add_mouse_listener SelectAction.new
      entity.add_component_listener MoveAction.new
      #@entities << entity
      @cm.register_component entity

      @panel.repaint
      #entity.set_opaque true
      entity
    end

    def add_endpoint(type, entity, initX, initY)
      ep = Endpoint.new
      ep.type = type
      ep.entityParent = entity
      entity.endpoints << ep
      #ep.direction = direction
      #ep.offset = offset
      ep.set_bounds initX, initY, ENDPOINT_WIDTH, ENDPOINT_HEIGHT
      ep.reset_direction
      ep.reset_position

      @panel.add ep
      @cm.register_component ep

      #TODO register additional listeners
      ep.add_component_listener MoveAction.new
      ep.add_mouse_listener EndpointMouseAction.new

      @panel.repaint

      return ep
    end

    def add_connection(source, target, sourcePoint, targetPoint, sType, tType, name, definition)
      sourceX = source.get_x
      sourceY = source.get_y

      targetX = target.get_x
      targetY = target.get_y


      line = Line2D::Double.new  sourcePoint, targetPoint

      source_intersecting_line = get_intersecting_line source, line
      target_intersecting_line = get_intersecting_line target, line

      source_intersecting_point = get_intersection_point line.get_p1,
                                                         line.get_p2,
                                                         source_intersecting_line.get_p1,
                                                         source_intersecting_line.get_p2


      target_intersecting_point = get_intersection_point line.get_p1,
                                                         line.get_p2,
                                                         target_intersecting_line.get_p1,
                                                         target_intersecting_line.get_p2

      sEP = add_endpoint sType, source, source_intersecting_point.get_x, source_intersecting_point.get_y
      tEP = add_endpoint tType, target, target_intersecting_point.get_x, target_intersecting_point.get_y

      connection = Connection.new sEP, tEP, name, definition

      @connections << connection
      connection
    end

    def get_intersecting_line entity, connnectLine
      entityX = entity.get_x
      entityY = entity.get_y

      edges = []

      #Top edge
      edges << (Line2D::Double.new entityX, entityY, entityX + ENTITY_WIDTH, entityY)
      #Bottom edge
      edges << (Line2D::Double.new entityX, entityY + ENTITY_HEIGHT, entityX + ENTITY_WIDTH, entityY + ENTITY_HEIGHT)
      #Left edge
      edges << (Line2D::Double.new entityX, entityY, entityX, entityY + ENTITY_HEIGHT)
      #Right edge
      edges <<  (Line2D::Double.new entityX + ENTITY_WIDTH, entityY, entityX + ENTITY_WIDTH, entityY + ENTITY_HEIGHT)

      edges.each do |e|
        return e if connnectLine.intersects_line e
      end

    end

    def get_intersection_point pointA, pointB, pointC, pointD
      xA, yA = pointA.get_x, pointA.get_y
      xB, yB = pointB.get_x, pointB.get_y
      xC, yC = pointC.get_x, pointC.get_y
      xD, yD = pointD.get_x, pointD.get_y

      interX = xC + (((((yC-yA)*(xB-xA)) - ((xC-xA)*(yB-yA))) / (((xD-xC)*(yB-yA)) - ((yD-yC)*(xB-xA)))) * (xD-xC))
      interY = yC + (((((yC-yA)*(xB-xA)) - ((xC-xA)*(yB-yA))) / (((xD-xC)*(yB-yA)) - ((yD-yC)*(xB-xA)))) * (yD-yC))


      return Point2D::Double.new interX, interY

    end

end



Modeler.new