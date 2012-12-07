include Java

Dir[File.dirname(__FILE__) + '/components/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/actions/*.rb'].each {|file| require file }

require 'erb'

require "rexml/document"
include REXML

import java.awt.BorderLayout
import javax.swing.JPanel
import javax.swing.JFrame
import javax.swing.ImageIcon
import javax.swing.JButton
import javax.swing.JMenuBar
import javax.swing.JMenu
import javax.swing.JSplitPane
import javax.swing.JToolBar
import javax.swing.JTextArea
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
import java.awt.event.ActionEvent
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

# HIT-Modeler is graphical editor for creating and management of conceptual data models according to HIT
# methodology. Modeler class represent the main application window and its typical usage looks like:
# * app = Modeler.new
# * app.set_visible true
# However, its basic functionality, such as adding components, import/export can be still used without making
# the window visible
# Warning: Make sure that all files from '/src/jars/' directory are on the classpath
#
# Author::    Stanislav Chren (mailto:stanislavch@gmail.com)
# Copyright:: Copyright (c) 2012
# License::   GPL-3.0
class Modeler < JFrame

  attr_accessor :draw_type,         # currently selected mode - "pointer/kernel/associative/descriptive/connection"
                :entities,          # collection of model's entities
                :connections,       # collection of mddel's connections
                :focus,             # currently selected entity/connection
                :entity_dialog,     # dialog for displaying entity's properties
                :connection_dialog, # dialog for displaying connection's properties
                :panel,             # panel, which model is drawn in
                :def_panel,         # panel, which the current definition shows in
                :max_id,            # last assigned id for entity
                :current_file       # current open model file name

  MODEL_WIDTH = 1024
  MODEL_HEIGHT = 768
  ENTITY_WIDTH = 110
  ENTITY_HEIGHT = 60
  ENDPOINT_WIDTH = 16
  ENDPOINT_HEIGHT = 16
  DEFAULT_SPLIT_PANE_HEIGHT = 200 
  PATH_TO_TEMPLATE = File.expand_path("resources/templates/model.html.erb", File.dirname(__FILE__))
  DEFAULT_FILE_NAME = "<new model>"
  APP_NAME = "HIT Modeler"

  def initialize
    super APP_NAME

    @entities = []
    @connections = []
    @cm = ComponentMover.new
    @max_id = 0

    self.update_current_file DEFAULT_FILE_NAME
    self.init_ui
  end

  def update_current_file file
    @current_file = file
    self.setTitle APP_NAME + " - " + @current_file
  end

  # Setups application
  def init_ui
    #Actions and listeners setup
    self.init_actions

    #Menu setup
    self.init_menu

    #Toolbar setup
    self.init_toolbar

    #Panel setup
    self.init_panel

    #Dialogs setup
    self.init_dialogs

    #Frame setup
    self.init_frame
  end

    # Creates entity and adds it to the model. Additionally, it registers all necessary listeners.
    def add_entity(name, type, definition, x, y)
      entity = Entity.new
      entity.id = get_next_free_entity_id
      entity.type = type
      entity.definition = definition
      entity.set_tool_tip_text definition

      if name.empty? || name.nil?
        name = "untitled"
      else
        entity.name = name
      end

      entity.set_bounds x, y, ENTITY_WIDTH, ENTITY_HEIGHT
      @panel.add entity

      entity.add_mouse_listener @select_action
      entity.add_component_listener @move_action
      @entities << entity
      @cm.register_component entity

      @panel.repaint
      entity
    end

    # Adds endpoint to the given entity. Initial position is recomputed based on position of the entity
    # and input position. Listeners are registered as well in order to make endpoint selectable and movable
    def add_endpoint(type, entity, init_x, init_y)
      ep = Endpoint.new
      ep.type = type
      ep.entity_parent = entity
      entity.endpoints << ep

      ep.set_bounds init_x, init_y, ENDPOINT_WIDTH, ENDPOINT_HEIGHT

      ep.reset_direction
      ep.reset_position

      @panel.add ep
      @cm.register_component ep

      ep.add_component_listener @move_action
      ep.add_mouse_listener @endpoint_mouse_action
      ep.add_mouse_listener @select_action

      @panel.repaint

      return ep
    end

    # Creates connection and adds it to the model. It should be used when connection is created by dragging mouse from
    # source entity to target entity. Source point and target point are points located inside of the entities bounds
    # and are used for computing initial position of the endpoints. It works as follows:
    # * line object is constructed between interior points of source and target entities
    # * for both entities is determined, which side of the entity is intersected by this line
    # * points of intersection are computed
    # * these points are used as initial positions of the endpoints
    # Label with connection's name is created as well and is made movable
    def add_connection(source, target, source_point, target_point, s_type, t_type, name, definition)

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

    # Similar to add_connection method. Only difference is, that given points are the actual initial positions of
    # endpoints. No further computation is used.
    def add_connection_specific_endpoints(source, target, source_point, target_point, s_type, t_type, name, definition)

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

    # Returns edge of the entity which is intersected by given line. Edge is returned as Line2D object
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

    # Returns Point2D object representing intersection point of the 2 lines. Lines are given by their endpoints
    def get_intersection_point point_a, point_b, point_c, point_d
      x_a, y_a = point_a.get_x, point_a.get_y
      x_b, y_b = point_b.get_x, point_b.get_y
      x_c, y_c = point_c.get_x, point_c.get_y
      x_d, y_d = point_d.get_x, point_d.get_y

      inter_x = x_c + (((((y_c-y_a)*(x_b-x_a)) - ((x_c-x_a)*(y_b-y_a))) / (((x_d-x_c)*(y_b-y_a)) - ((y_d-y_c)*(x_b-x_a)))) * (x_d-x_c))
      inter_y = y_c + (((((y_c-y_a)*(x_b-x_a)) - ((x_c-x_a)*(y_b-y_a))) / (((x_d-x_c)*(y_b-y_a)) - ((y_d-y_c)*(x_b-x_a)))) * (y_d-y_c))

      return Point2D::Double.new inter_x, inter_y
    end

    def get_next_free_entity_id
      # TODO: make thread-safe!
      return @max_id += 1
    end

    # Returns entity with given id
    def get_entity id
      @entities.each do |e|
        return e if e.id == id
      end
    end

    # Clears whole content of the model
    def clear_model
      @panel.remove_all
      @connections.clear
      @entities.clear
      self.clear_displayed_definition      
    end

    # Saves model into specified xml file
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
      formatter = Formatters::Default.new   # using Pretty formatter corrupts indentation in definitions
      formatter.write(doc, output_file)
      output_file.close

    end

    # Loads model from given xml file. For details of the file structure, see save_model method
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
      end
      @panel.repaint
    end

    # Exports model to given jpg file. First, it takes snapshot of the whole panel, then it is cropped, so
    # that it contains only the actual model
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

    # Returns minimal bounding rectangle of the model.
    # TODO: at this momemnt only entities are considered (+ additional space in case of endpoints is added).
    #       This should be reworked into more general approach, where all components are considered,
    #       including connection labels
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

        #if leftmost_x - 17 > 0
        #  leftmost_x = leftmost_x -17
        #else
        #  leftmost_x = 0
        #end

        #if rightmost_x + 17 < @panel.get_width
        #  rightmost_x = rightmost_x +17
        #else
        #  rightmost_x = @panel.get_width
        #end

        #if top_y - 17 > 0
        #  top_y = top_y -17
        #else
        #  top_y = 0
        #end

        #if bottom_y + 17 < @panel.get_height
        #  bottom_y = bottom_y + 17
        #else
        #  bottom_y = @panel.get_height
        #end

      end
      return Rectangle.new leftmost_x, top_y, rightmost_x - leftmost_x, bottom_y - top_y
    end

    # Exports model with given ERB template to given file
    def export_to_template template, file
      renderer = ERB.new(File.read(template))
      output = renderer.result binding
      output_file = File.open file, 'w'
      output_file << output
      output_file.close
    end

  def perform_save_as_action
      file_chooser = JFileChooser.new
    
      filter = FileNameExtensionFilter.new "xml files", "xml"
    
      file_chooser.set_accept_all_file_filter_used false
      file_chooser.addChoosableFileFilter filter
    
      ret = file_chooser.showDialog self, "Save"
    
      if ret == JFileChooser::APPROVE_OPTION
        self.update_current_file file_chooser.getSelectedFile.absolute_path
    
        self.save_model @current_file
        JOptionPane.show_message_dialog self, "Model has been saved to #{@current_file}.", "Save file", JOptionPane::INFORMATION_MESSAGE
      end 
  end

    # Setups application menu. All items should have assigned icons, mnemonics and accelerators. Default icon location
    # is in 'resources/icons' directory
    def init_menu
      @menubar = JMenuBar.new

      @file_menu = JMenu.new "File"
      @file_menu.set_mnemonic KeyEvent::VK_F

      @tools_menu = JMenu.new "Tools"
      @tools_menu.set_mnemonic KeyEvent::VK_T

      @help_menu = JMenu.new "Help"
      @help_menu.set_mnemonic KeyEvent::VK_H

      icon_path = File.expand_path("resources/icons/new.png", File.dirname(__FILE__))
      @item_new = JMenuItem.new "New", (ImageIcon.new icon_path)
      @item_new.set_mnemonic KeyEvent::VK_N
      @item_new.set_accelerator KeyStroke.get_key_stroke(KeyEvent::VK_N, ActionEvent::CTRL_MASK)
      @item_new.add_action_listener do |e|
        self.update_current_file DEFAULT_FILE_NAME
        self.clear_model
        @panel.repaint
      end

      icon_path = File.expand_path("resources/icons/Save16.gif", File.dirname(__FILE__))
      @item_save_as = JMenuItem.new "Save As ...", (ImageIcon.new icon_path)
      @item_save_as.add_action_listener do |e|
        self.perform_save_as_action
      end

      icon_path = File.expand_path("resources/icons/Save16.gif", File.dirname(__FILE__))
      @item_save = JMenuItem.new "Save", (ImageIcon.new icon_path)
      @item_save.set_mnemonic KeyEvent::VK_S
      @item_save.set_accelerator KeyStroke.get_key_stroke(KeyEvent::VK_S, ActionEvent::CTRL_MASK)
      @item_save.add_action_listener do |e|
        if @current_file != DEFAULT_FILE_NAME
          self.save_model @current_file
          JOptionPane.show_message_dialog self, "Model has been saved to #{@current_file}.", "Save file", JOptionPane::INFORMATION_MESSAGE
        else
          self.perform_save_as_action
        end
      end

      icon_path = File.expand_path("resources/icons/open.png", File.dirname(__FILE__))
      @item_load = JMenuItem.new "Load", (ImageIcon.new icon_path)
      @item_load.set_mnemonic KeyEvent::VK_L
      @item_load.set_accelerator KeyStroke.get_key_stroke(KeyEvent::VK_L, ActionEvent::CTRL_MASK)
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
          self.update_current_file file
        end
      end

      icon_path = File.expand_path("resources/icons/exit.png", File.dirname(__FILE__))
      @item_exit = JMenuItem.new "Exit", (ImageIcon.new icon_path)
      @item_exit.set_mnemonic KeyEvent::VK_E
      @item_exit.set_accelerator KeyStroke.get_key_stroke(KeyEvent::VK_X, ActionEvent::CTRL_MASK)
      @item_exit.add_action_listener do |e|
        System.exit 0
      end

      icon_path = File.expand_path("resources/icons/image.png", File.dirname(__FILE__))
      @item_export_to_jpg = JMenuItem.new "Export to JPG", (ImageIcon.new icon_path)
      @item_export_to_jpg.set_mnemonic KeyEvent::VK_J
      @item_export_to_jpg.set_accelerator KeyStroke.get_key_stroke(KeyEvent::VK_J, ActionEvent::CTRL_MASK)
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

      icon_path = File.expand_path("resources/icons/html.png", File.dirname(__FILE__))
      @item_export_to_html = JMenuItem.new "Export to HTML", (ImageIcon.new icon_path)
      @item_export_to_html.set_mnemonic KeyEvent::VK_H
      @item_export_to_html.set_accelerator KeyStroke.get_key_stroke(KeyEvent::VK_H, ActionEvent::CTRL_MASK)
      @item_export_to_html.add_action_listener do |e|
        file_chooser = JFileChooser.new

        filter = FileNameExtensionFilter.new "html", "html", "htm"
        file_chooser.set_accept_all_file_filter_used false
        file_chooser.addChoosableFileFilter filter
        ret = file_chooser.showDialog self, "Export"


        if ret == JFileChooser::APPROVE_OPTION
          file = file_chooser.getSelectedFile.absolute_path
          self.export_to_template PATH_TO_TEMPLATE, file
          JOptionPane.show_message_dialog self, "Model has been exported.", "Export model", JOptionPane::INFORMATION_MESSAGE
        end
      end

      icon_path = File.expand_path("resources/icons/Information16.gif", File.dirname(__FILE__))
      @item_about = JMenuItem.new "About", (ImageIcon.new icon_path)
      @item_about.set_mnemonic KeyEvent::VK_A
      @item_about.set_accelerator KeyStroke.get_key_stroke("F1")
      @item_about.add_action_listener do |e|
        JOptionPane.show_message_dialog self, "HIT-Modeler v0.5\nAuthor: Stanislav Chren\n2012", "About", JOptionPane::PLAIN_MESSAGE
      end


      [@item_new,
       @item_load,
       @item_save,
       @item_save_as,
       @item_exit].each{ |c| @file_menu.add c}

      [@item_export_to_jpg,
       @item_export_to_html].each{ |c| @tools_menu.add c}

      @help_menu.add @item_about

      @menubar.add @file_menu
      @menubar.add @tools_menu
      @menubar.add @help_menu
      self.set_jmenu_bar @menubar
    end

    # Setups toolbar
    def init_toolbar
      @toolbar = JToolBar.new
      @toolbar.set_rollover true

      #Toolbar buttons
      icon_path = File.expand_path("resources/icons/pointer.png", File.dirname(__FILE__))
      @pointer_button = JToggleButton.new ImageIcon.new icon_path
      @pointer_button.set_action_command "pointer"
      @pointer_button.set_tool_tip_text "Select tool"

      icon_path = File.expand_path("resources/icons/kernel.png", File.dirname(__FILE__))
      @kernel_button = JToggleButton.new ImageIcon.new icon_path
      @kernel_button.set_action_command "kernel"
      @kernel_button.set_tool_tip_text "Create kernel entity"

      icon_path = File.expand_path("resources/icons/associative.png", File.dirname(__FILE__))
      @assoc_button = JToggleButton.new ImageIcon.new icon_path
      @assoc_button.set_action_command "associative"
      @assoc_button.set_tool_tip_text "Create associative entity"

      icon_path = File.expand_path("resources/icons/descriptive.png", File.dirname(__FILE__))
      @desc_button = JToggleButton.new ImageIcon.new icon_path
      @desc_button.set_action_command "descriptive"
      @desc_button.set_tool_tip_text "Create characteristic entity"

      icon_path = File.expand_path("resources/icons/connection.png", File.dirname(__FILE__))
      @connect_button = JToggleButton.new ImageIcon.new icon_path
      @connect_button.set_action_command "connection"
      @connect_button.set_tool_tip_text "Create connection"

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
      @toolbar.add @pointer_button
      @toolbar.add_separator
      [@kernel_button,
       @assoc_button,
       @desc_button].each {|c| @toolbar.add c}
      @toolbar.add_separator
      @toolbar.add @connect_button

      # Sets draw_type after switching button selection
      # and enables/disables dragging
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

      # Adding toolbar to frame
      self.add @toolbar, BorderLayout::NORTH
    end

    def init_editor_panel parentFrame
      @panel = EditorPanel.new
      @panel.parent_frame = parentFrame
      @panel.set_layout nil
      @panel.set_background Color.new 255, 255, 255
      @panel.set_preferred_size Dimension.new 1024, 1024

      #Adding delete action to remove components
      stroke = KeyStroke.getKeyStroke(KeyEvent::VK_DELETE)
      input_map = @panel.get_input_map JComponent::WHEN_IN_FOCUSED_WINDOW
      input_map.put stroke, "DELETE"
      @panel.get_action_map.put "DELETE", DeleteAction.new
 
      #Adding scroll pane
      @scroll_pane = JScrollPane.new @panel
      @scroll_pane.set_viewport_view @panel
      @scroll_pane.get_vertical_scroll_bar.set_unit_increment 10
    end

    def init_definition_panel
      @def_panel = JTextArea.new ""
      @def_panel.set_editable false

      #Adding scroll pane
      @def_scroll_pane = JScrollPane.new @def_panel
      @def_scroll_pane.set_viewport_view @def_panel
      @def_scroll_pane.get_vertical_scroll_bar.set_unit_increment 10
    end
  
    def init_panel
      init_editor_panel self
      init_definition_panel
      
      #Adding split pane
      @split_pane = JSplitPane.new JSplitPane::VERTICAL_SPLIT,
                                 @scroll_pane, @def_scroll_pane
      @split_pane.set_one_touch_expandable true
      @split_pane.set_divider_location MODEL_HEIGHT - DEFAULT_SPLIT_PANE_HEIGHT
      
      #Provide minimum sizes for the two components in the split pane
      minimumSize = Dimension.new 100, 100
      @scroll_pane.set_minimum_size minimumSize
      @def_scroll_pane.set_minimum_size minimumSize

      self.get_content_pane.add @split_pane

      #Registering listener for adding new components
      @panel.add_mouse_listener PanelMouseAction.new self

    end

    # Setups custom dialogs used by application
    def init_dialogs
      @entity_dialog = EntityDialog.new self, true
      @entity_dialog.set_visible false

      @connection_dialog = ConnectionDialog.new self, true
      @connection_dialog.set_visible false
    end

    # Setups main frame
    def init_frame
      self.set_default_close_operation JFrame::EXIT_ON_CLOSE
      self.set_size MODEL_WIDTH, MODEL_HEIGHT
      self.set_location_relative_to nil
      self.set_visible false
    end

    # Setups main listener objects
    def init_actions
      @select_action = SelectAction.new self
      @endpoint_mouse_action = EndpointMouseAction.new
      @move_action = MoveAction.new
    end

    def display_definition definition
      @def_panel.set_text definition
    end

    def clear_displayed_definition
      @def_panel.set_text ""
    end
  
end
