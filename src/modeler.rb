include Java

require 'components/entity.rb'
require 'components/entity_dialog.rb'
require 'components/connection_dialog.rb'
require 'components/endpoint.rb'
require 'components/editor_panel.rb'
require 'components/connection.rb'
require 'actions/select_action.rb'
require 'actions/delete_action.rb'
require 'actions/panel_mouse_action.rb'
require 'actions/move_action.rb'
require 'actions/endpoint_mouse_action.rb'

require "rexml/document"
include REXML

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
import javax.swing.filechooser.FileNameExtensionFilter
import javax.swing.JFileChooser
import javax.swing.SwingWorker
import java.awt.Cursor
import java.awt.image.BufferedImage
import javax.imageio.ImageIO
import java.awt.Rectangle
java_import 'ComponentMover'

puts $CLASSPATH
class Modeler < JFrame

  attr_accessor :draw_type, :entities, :connections, :focus, :entity_dialog, :connection_dialog, :panel, :max_id

  ENTITY_WIDTH = 110
  ENTITY_HEIGHT = 60
  ENDPOINT_WIDTH = 16
  ENDPOINT_HEIGHT = 16



  def initialize
    super "HIT Modeler"

    @select_action = SelectAction.new
    @endpoint_mouse_action = EndpointMouseAction.new
    @move_action = MoveAction.new


    @entities, @connections = []
    @cm = ComponentMover.new
    @max_id = 0

    self.init_ui
  end

  def init_ui
    @connections = []
    @entities = []



    #Menu definition
    @menubar = JMenuBar.new

    @file_menu = JMenu.new "File"
    @tools_menu = JMenu.new "Tools"
    @help_menu = JMenu.new "Help"

    @item_new = JMenuItem.new "New"
    @item_new.add_action_listener do |e|
      self.clear_model
      @panel.repaint
    end

    @item_save = JMenuItem.new "Save"
    @item_save.add_action_listener do |e|
      file_chooser = JFileChooser.new

      filter = FileNameExtensionFilter.new "xml files", "xml"

      file_chooser.set_accept_all_file_filter_used false
      file_chooser.addChoosableFileFilter filter

      ret = file_chooser.showDialog self, "Save"


      if ret == JFileChooser::APPROVE_OPTION
        file = file_chooser.getSelectedFile.absolute_path

        self.save_model file
        JOptionPane.show_message_dialog self, "Model has been saved.", "Save file", JOptionPane::INFORMATION_MESSAGE
      end
    end
    @item_load = JMenuItem.new "Load"
    @item_load.add_action_listener do |e|
      file_chooser = JFileChooser.new

      filter = FileNameExtensionFilter.new "xml files", "xml"
      file_chooser.set_accept_all_file_filter_used false
      file_chooser.addChoosableFileFilter filter
      ret = file_chooser.showDialog self, "Load"


      if ret == JFileChooser::APPROVE_OPTION
        file = file_chooser.getSelectedFile.absolute_path
        self.set_cursor(Cursor.get_predefined_cursor(Cursor::WAIT_CURSOR))
        self.load_model file
        self.set_cursor nil
      end
    end
    @item_exit = JMenuItem.new "Exit"

    @item_exit.set_tool_tip_text "Exit application"
    @item_exit.add_action_listener do |e|
      System.exit 0
    end


    @item_export_to_jpg = JMenuItem.new "Export to JPG"
    @item_export_to_jpg.add_action_listener do |e|
      file_chooser = JFileChooser.new

      filter = FileNameExtensionFilter.new "jpg", "jpg"
      file_chooser.set_accept_all_file_filter_used false
      file_chooser.addChoosableFileFilter filter
      ret = file_chooser.showDialog self, "Export"


      if ret == JFileChooser::APPROVE_OPTION
        file = file_chooser.getSelectedFile.absolute_path
        self.export_to_jpg file
        JOptionPane.show_message_dialog self, "Model has been exported to JPG.", "Export model", JOptionPane::INFORMATION_MESSAGE
      end
    end


    @item_export_to_html = JMenuItem.new "Export to HTML"

    @item_about = JMenuItem.new "About"


    [@item_new,
     @item_save,
     @item_load,
     @item_exit].each{ |c| @file_menu.add c}

    [@item_export_to_jpg,
     @item_export_to_html].each{ |c| @tools_menu.add c}

    @help_menu.add @item_about

    @menubar.add @file_menu
    @menubar.add @tools_menu
    @menubar.add @help_menu
    self.set_jmenu_bar @menubar

    #-----------------------------------------------------------

    #Toolbar definition
    @toolbar = JToolBar.new

    #Toolbar buttons
    @pointer_button = JToggleButton.new "pointer"
    @kernel_button = JToggleButton.new "kernel"
    @assoc_button = JToggleButton.new "associative"
    @desc_button = JToggleButton.new "descriptive"
    @connect_button = JToggleButton.new "connection"

    #Adding buttons into button group, so that only one is selected at a time
    @group = ButtonGroup.new
    [@pointer_button,
     @kernel_button,
     @assoc_button,
     @desc_button,
     @connect_button].each {|c| @group.add c}

    #Default selection
    @group.set_selected(@pointer_button.get_model,true)
    @draw_type = "pointer"

    #Adding button into toolbar
    #TODO replace text with icons
    [@pointer_button,
     @kernel_button,
     @assoc_button,
     @desc_button,
     @connect_button].each {|c| @toolbar.add c}

    #Sets draw_type after switching button selection
    #and enables/disables dragging
    [@pointer_button,
     @kernel_button,
     @assoc_button,
     @desc_button,
     @connect_button].each {
      |c| c.add_action_listener do |e|
        @draw_type = e.get_action_command

        if @draw_type == "connection"
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
    @panel.parent_frame = self
    puts @panel.parent_frame.class.to_s
    @panel.set_layout nil
    @panel.set_background Color.new 255, 255, 255
    @panel.set_preferred_size Dimension.new 1024, 1024

    #Adding delete action to remove components
    stroke = KeyStroke.getKeyStroke(KeyEvent::VK_DELETE)
    input_map = @panel.get_input_map JComponent::WHEN_IN_FOCUSED_WINDOW
    input_map.put stroke, "DELETE"
    @panel.get_action_map.put "DELETE", DeleteAction.new

    #Adding scrollbars to JPanel
    @scroll_pane = JScrollPane.new @panel
    @scroll_pane.set_viewport_view @panel
    @scroll_pane.get_vertical_scroll_bar.set_unit_increment 10
    self.get_content_pane.add @scroll_pane

    #Registering listener for adding new components
    @panel.add_mouse_listener PanelMouseAction.new


    add_entity "assoc", "associative", nil, 200, 200
    e1 = add_entity "kernel", "kernel", nil, 50, 50
    e2 = add_entity "desc", "descriptive", "aaa", 300, 10

    c1 = add_connection e1, e2, (Point2D::Double.new 50+55, 50+30), (Point2D::Double.new 300+55, 10+30), "0m", "0m", "aaa", "dd"




    #-----------------------------------------------------------

    #Frame setup
    self.set_default_close_operation JFrame::EXIT_ON_CLOSE
    self.set_size 1024, 768
    self.set_location_relative_to nil

    #TODO Remove before testing
    self.set_visible true

    #Entity property dialog setup
    @entity_dialog = EntityDialog.new self, true
    @entity_dialog.set_visible false

    @connection_dialog = ConnectionDialog.new self, true
    @connection_dialog.set_visible false


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

      #entity.add_mouse_listener SelectAction.new
      entity.add_mouse_listener @select_action
      entity.add_component_listener @move_action
      @entities << entity
      @cm.register_component entity

      @panel.repaint
      #entity.set_opaque true
      entity
    end

    def add_endpoint(type, entity, initX, initY)
      ep = Endpoint.new
      ep.type = type
      ep.entity_parent = entity
      entity.endpoints << ep

      ep.set_bounds initX, initY, ENDPOINT_WIDTH, ENDPOINT_HEIGHT

      ep.reset_direction
      ep.reset_position

      @panel.add ep
      @cm.register_component ep

      #TODO register additional listeners
      ep.add_component_listener @move_action
      ep.add_mouse_listener @endpoint_mouse_action
      ep.add_mouse_listener @select_action

      @panel.repaint

      return ep
    end

    def add_connection(source, target, source_point, target_point, s_type, t_type, name, definition)
      source_x = source.get_x
      source_y = source.get_y

      target_x = target.get_x
      target_y = target.get_y


      line = Line2D::Double.new  source_point, target_point

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

      sEP = add_endpoint s_type, source, source_intersecting_point.get_x, source_intersecting_point.get_y
      tEP = add_endpoint t_type, target, target_intersecting_point.get_x, target_intersecting_point.get_y

      connection = Connection.new sEP, tEP, name, definition

      [sEP,tEP].each {|ep| ep.connection = connection}

      label = JLabel.new name
      @panel.add label
      @cm.register_component label


      label.set_size label.get_preferred_size
      connection.label = label
      connection.reset_label_position

      @connections << connection
      connection
    end

    def add_connection_specific_endpoints(source, target, source_point, target_point, s_type, t_type, name, definition)
      ource_x = source.get_x
      source_y = source.get_y

      target_x = target.get_x
      target_y = target.get_y

      sEP = add_endpoint s_type, source, source_point.get_x, source_point.get_y
      tEP = add_endpoint t_type, target, target_point.get_x, target_point.get_y

      connection = Connection.new sEP, tEP, name, definition

      [sEP,tEP].each {|ep| ep.connection = connection}

      label = JLabel.new name
      @panel.add label
      @cm.register_component label


      label.set_size label.get_preferred_size
      connection.label = label
      connection.reset_label_position

      @connections << connection
      connection
    end

    def get_intersecting_line entity, connnectLine
      entity_x = entity.get_x
      entity_y = entity.get_y

      edges = []

      #Top edge
      edges << (Line2D::Double.new entity_x, entity_y, entity_x + ENTITY_WIDTH, entity_y)
      #Bottom edge
      edges << (Line2D::Double.new entity_x, entity_y + ENTITY_HEIGHT, entity_x + ENTITY_WIDTH, entity_y + ENTITY_HEIGHT)
      #Left edge
      edges << (Line2D::Double.new entity_x, entity_y, entity_x, entity_y + ENTITY_HEIGHT)
      #Right edge
      edges <<  (Line2D::Double.new entity_x + ENTITY_WIDTH, entity_y, entity_x + ENTITY_WIDTH, entity_y + ENTITY_HEIGHT)

      edges.each do |e|
        return e if connnectLine.intersects_line e
      end

    end

    def get_intersection_point point_a, point_b, point_c, point_d
      x_a, y_a = point_a.get_x, point_a.get_y
      x_b, y_b = point_b.get_x, point_b.get_y
      x_c, y_c = point_c.get_x, point_c.get_y
      x_d, y_d = point_d.get_x, point_d.get_y

      inter_x = x_c + (((((y_c-y_a)*(x_b-x_a)) - ((x_c-x_a)*(y_b-y_a))) / (((x_d-x_c)*(y_b-y_a)) - ((y_d-y_c)*(x_b-x_a)))) * (x_d-x_c))
      inter_y = y_c + (((((y_c-y_a)*(x_b-x_a)) - ((x_c-x_a)*(y_b-y_a))) / (((x_d-x_c)*(y_b-y_a)) - ((y_d-y_c)*(x_b-x_a)))) * (y_d-y_c))


      return Point2D::Double.new inter_x, inter_y

    end

    def get_entity id
      @entities.each do |e|
        return e if e.id == id
      end
    end

    def clear_model
      @panel.remove_all
      @connections.clear
      @entities.clear
    end

    def save_model file
      doc = Document.new
      doc << XMLDecl.new

      model_element = Element.new "model"
      doc << model_element
      entities_element = Element.new "entities"
      model_element << entities_element
      connections_element = Element.new "connections"
      model_element << connections_element

      @entities.each do |e|
        entity_element = Element.new "entity"
        el = Element.new "id"
        el.text = e.id
        entity_element << el

        el = Element.new "name"
        el.text = e.name
        entity_element << el

        el = Element.new "type"
        el.text = e.type
        entity_element << el

        el = Element.new "definition"
        el.text = e.definition
        entity_element << el

        el = Element.new "x"
        el.text = e.get_x
        entity_element << el

        el = Element.new "y"
        el.text = e.get_y
        entity_element << el

        entities_element << entity_element
      end

      @connections.each do |c|
        connection_element = Element.new "connection"

        el = Element.new "name"
        el.text = c.name
        connection_element << el

        el = Element.new "definition"
        el.text = c.definition
        connection_element << el

        el = Element.new "source-entity-id"
        el.text = c.source_ep.entity_parent.id
        connection_element << el

        el = Element.new "target-entity-id"
        el.text = c.target_ep.entity_parent.id
        connection_element << el

        el = Element.new "source-point-type"
        el.text = c.source_ep.type
        connection_element << el

        el = Element.new "target-point-type"
        el.text = c.target_ep.type
        connection_element << el

        el = Element.new "source-point-x"
        el.text = c.source_ep.get_x
        connection_element << el

        el = Element.new "source-point-y"
        el.text = c.source_ep.get_y
        connection_element << el

        el = Element.new "target-point-x"
        el.text = c.target_ep.get_x
        connection_element << el

        el = Element.new "target-point-y"
        el.text = c.target_ep.get_y
        connection_element << el

        el = Element.new "label-x"
        el.text = c.label.get_x
        connection_element << el

        el = Element.new "label-y"
        el.text = c.label.get_y
        connection_element << el

        connections_element << connection_element
      end

      output_file = File.open file, 'w'
      formatter = Formatters::Pretty.new(2)
      formatter.compact = true # This is the magic line that does what you need!
      formatter.write(doc, output_file)
      output_file.close

    end

    def load_model file
      self.clear_model

      xml_file = File.new file
      doc = Document.new xml_file

      doc.elements.each("model/entities/entity") do  |element|

        id = element.elements[1].text.to_i
        name =  element.elements[2].text
        type = element.elements[3].text
        definition = element.elements[4].text
        x = element.elements[5].text.to_i
        y = element.elements[6].text.to_i

        if id.to_i > @max_id
          @max_id = id.to_i
        end

        ent = self.add_entity name, type, definition, x, y
        ent.id = id
        puts ent.id
       # @panel.repaint
      end

      doc.elements.each("model/connections/connection") do |element|
        name = element.elements[1].text
        definition = element.elements[2].text
        source_entity_id = element.elements[3].text.to_i
        target_entity_id = element.elements[4].text.to_i
        source_point_type = element.elements[5].text
        target_point_type = element.elements[6].text
        source_point_x = element.elements[7].text.to_i
        source_point_y = element.elements[8].text.to_i
        target_point_x = element.elements[9].text.to_i
        target_point_y = element.elements[10].text.to_i
        label_x = element.elements[11].text.to_i
        label_y = element.elements[12].text.to_i

        source_entity = self.get_entity source_entity_id
        target_entity = self.get_entity target_entity_id
        source_point = Point2D::Double.new source_point_x, source_point_y
        target_point = Point2D::Double.new target_point_x, target_point_y

        con = self.add_connection_specific_endpoints source_entity,
                                                     target_entity,
                                                     source_point,
                                                     target_point,
                                                     source_point_type,
                                                     target_point_type,
                                                     name,
                                                     definition

        con.label.set_location label_x, label_y
        #@panel.repaint
      end
      @panel.repaint
    end

    def export_to_jpg file
      width = @panel.get_width
      height = @panel.get_height

      buffered_image = BufferedImage.new width, height, BufferedImage::TYPE_INT_RGB
      graphics  = buffered_image.create_graphics
      @panel.paint(graphics);

      cropping_rectangle = self.get_bounding_rectangle
      cropped_image = buffered_image.get_subimage cropping_rectangle.get_x,
                                                  cropping_rectangle.get_y,
                                                  cropping_rectangle.get_width,
                                                  cropping_rectangle.get_height

      output_file = java.io.File.new file

      ImageIO.write cropped_image, "jpg", output_file

    end

    def get_bounding_rectangle
      leftmost_x = @panel.get_width
      rightmost_x = 0
      top_y = @panel.get_height
      bottom_y = 0

      @entities.each do |e|
        e_x = e.get_x
        e_y = e.get_y

        if e_x < leftmost_x
          leftmost_x = e_x
        end

        if e_x + ENTITY_WIDTH > rightmost_x
          rightmost_x = e_x + ENTITY_WIDTH
        end

        if e_y < top_y
          top_y = e_y
        end

        if e_y + ENTITY_HEIGHT > bottom_y
          bottom_y = e_y + ENTITY_HEIGHT
        end
      end
      return Rectangle.new leftmost_x, top_y, rightmost_x - leftmost_x, bottom_y - top_y
    end

end


Modeler.new