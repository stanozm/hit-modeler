include Java

import java.awt.event.MouseAdapter
import javax.swing.SwingUtilities
import javax.swing.BorderFactory

class SelectAction < MouseAdapter

  def initialize
    @@pressedSource = nil

  end

  def mouseClicked e
    #Component which the mouse clicked on
    source = e.source

    clickcount = e.getClickCount

    #Main frame
    parent = (SwingUtilities.getWindowAncestor source)

    #Previous focus
    focus = parent.focus
    focusClass = focus.class.to_s

    if parent.drawType == "pointer"

      #Deselects previously selected entity
      if (!focus.nil?)  && (focusClass == "Entity")
        border = BorderFactory.create_line_border Color::black,1
        parent.focus.set_border border
        parent.panel.repaint
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


  def mousePressed e
    source = e.source
    parent = (SwingUtilities.getWindowAncestor source)

    if parent.drawType == "connection"
      puts source.name
      @@pressedSource = source
      border = BorderFactory.create_line_border Color::green, 2
      source.set_border border


    end
  end

  def mouseEntered e
    source = e.source
    parent = (SwingUtilities.getWindowAncestor source)

    if parent.drawType == "connection" && !@@pressedSource.nil?
      puts @@pressedSource.name
      if !source.equal? @@pressedSource && !@@pressedSource.nil?

        border = BorderFactory.create_line_border Color::green, 2
        source.set_border border

        sourcePoint = Point2D::Double.new @@pressedSource.get_x + 55, @@pressedSource.get_y + 30
        targetPoint = Point2D::Double.new source.get_x + 55, source.get_y + 30

        parent.add_connection @@pressedSource, source, sourcePoint, targetPoint, "0m", "0m", "bla", "empty"

        border = BorderFactory.create_line_border Color::black
        source.set_border border
        @@pressedSource.set_border border
        @@pressedSource = nil
        parent.panel.repaint
      end
    end

  end

  #Returns selected option from radio button group
  def return_selected options
    options.each do |option|
      return option if option.is_selected
    end
  end



end