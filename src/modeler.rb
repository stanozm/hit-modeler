include Java

require 'entity.rb'
require 'entity_dialog.rb'
require 'endpoint.rb'
require 'editor_panel.rb'

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
java_import 'ComponentMover'

puts $CLASSPATH
class Modeler < JFrame

  attr_accessor :drawType, :entities, :connections, :cm, :focus, :entityDialog

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
    @panel.set_layout nil
    @panel.set_background Color.new 255, 255, 255
    @panel.set_preferred_size Dimension.new 2048, 2048

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
    add_entity "kernel", "kernel", nil, 50, 50
    x = add_entity "desc", "descriptive", "aaa", 300, 10

    ep = Endpoint.new
    ep.set_bounds 400, 400, 16, 16
    ep.type = "0m"
    ep.direction = "up"
    #ep.set_border BorderFactory.create_line_border Color::black
    @panel.add ep
    ep.entityParent = x
    ep.add_mouse_listener SelectEntityAction.new
    @cm.register_component ep

    puts self.get_content_pane.get_graphics


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

      entity.add_mouse_listener SelectEntityAction.new
      #@entities << entity
      @cm.register_component entity

      @panel.repaint

      entity
    end

end

#Custom Listeners
class PanelMouseAction < MouseAdapter

  def mouseReleased e

    source = e.source
    x = e.getX
    y = e.getY

    parent = (SwingUtilities.getWindowAncestor source)
    type = parent.drawType

    if ["kernel","associative","descriptive"].include? type

      name = JOptionPane.showInputDialog parent, "Enter name:", "New entity", JOptionPane::PLAIN_MESSAGE, nil, nil, "untitled"

      if  !name.nil? && !name.empty?
        parent.add_entity name, type, nil, x, y
      end
    end
  end
end

class SelectEntityAction < MouseAdapter
  def mouseClicked e
    #Component which the mouse clicked on
    source = e.source



    clickcount = e.getClickCount

    #TODO following only for testing, remove aftewards !!!
    if source.class.to_s == "Endpoint"
      if clickcount == 1
        #source.reset_direction
        source.repaint
        puts "Direction " + source.direction
        puts "Offset "  + source.offset.to_s
      end
      if clickcount == 2
        source.reset_position
        source.repaint
      end
    end

    #Main frame
    parent = (SwingUtilities.getWindowAncestor source)

    #Previous focus
    focus = parent.focus
    focusClass = focus.class.to_s

    if parent.drawType == "pointer"

      #Deselects previously selected entity
      if (!focus.nil?)  && (focusClass == "Entity")
        border = BorderFactory.create_line_border Color::black
        parent.focus.set_border border
      end

      #Sets focus on currently selected entity
      parent.focus = source
      if source.class.to_s == "Entity"
        border = BorderFactory.create_line_border Color::blue, 2
        source.set_border border
      end
      #double-click

      #TODO consolidate with endpoint click!!!!!
      if clickcount == 2 && source.class.to_s == "Entity"

        #Obtain entity properties dialog
        propertyDialog = parent.entityDialog
        propertyDialog.closeAction = "cancel"

        propertyDialog.get_name_field.set_text source.name

        type = source.type

        #Selects radio button based on selected entity
        case type
          when "kernel"
            radio = propertyDialog.get_kernel_radio
          when "associative"
            radio = propertyDialog.get_associative_radio
          when "descriptive"
            radio = propertyDialog.get_descriptive_radio
        end
        propertyDialog.radioGroup.set_selected radio.get_model, true


        #Fills definition text area
        definition = source.definition
        propertyDialog.get_definition_area.set_text definition

        propertyDialog.set_visible true

        #Processes dialog input if okButton was clicked
        if propertyDialog.closeAction == "ok"
          source.name = propertyDialog.get_name_field.get_text
          source.definition = propertyDialog.get_definition_area.get_text
          source.set_tool_tip_text definition

          #Obtain selected radio button
          options = propertyDialog.radioGroup.get_elements
          selected = (return_selected options).get_text

          #Sets new type
          if selected == "characteristic"
            source.type = "descriptive"
          else
            source.type = selected
          end
          source.repaint

        end

      end

      #puts parent.focus.name

    end
  end

  #Returns selected option from radio button group
  def return_selected options
    options.each do |option|
      return option if option.is_selected
    end
  end

end

#Deletes selected entity and clears focus
class DeleteAction < AbstractAction
  def actionPerformed e

    source = e.source
    parent = SwingUtilities.getWindowAncestor source
    focus = parent.focus

    if !focus.nil?
      source.remove focus
      focus = nil
      source.repaint
    end

    puts e.source
    puts "mazem"
  end
end

Modeler.new