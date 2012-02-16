include Java

import java.awt.event.MouseAdapter
import javax.swing.SwingUtilities
import javax.swing.BorderFactory
import java.awt.Color
import java.awt.BasicStroke

class SelectAction < MouseAdapter

  SHOW_CONNECTION_DIALOG = true

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

      #Deselects previously selescted connectin
      if (!focus.nil?)  && (focusClass == "Connection")

        parent.focus.color = Color::black
        parent.focus.stroke = BasicStroke.new 1
        parent.focus.label.set_foreground Color::black
        parent.panel.repaint
      end

      #Sets focus on currently selected entity

      if source.class.to_s == "Entity"
        border = BorderFactory.create_line_border Color::blue, 2
        source.set_border border
        parent.focus = source
      end

      #Sets focus on connection of the currently selected endpoint
      if source.class.to_s == "Endpoint"
        focusConnection = source.connection
        focusConnection.color = Color::blue
        focusConnection.stroke = BasicStroke.new 2
        focusConnection.label.set_foreground Color::blue
        parent.focus = focusConnection
      end

      parent.panel.repaint
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

      #Showing connection dialog
      if clickcount == 2 && source.class.to_s == "Endpoint"

        connection = source.connection

        #Obtain entity properties dialog
        propertyDialog = parent.connectionDialog
        propertyDialog.closeAction = "cancel"

        propertyDialog.get_name_field.set_text connection.name

        propertyDialog.get_source_label.set_text "["+ connection.sourceEP.entityParent.name + "]"
        propertyDialog.get_target_label.set_text "["+ connection.targetEP.entityParent.name + "]"

        sourceType = connection.sourceEP.type
        puts sourceType

        targetType = connection.targetEP.type
        puts targetType

        #Selects radio button based on source point
        case sourceType
          when "0m"
            radio = propertyDialog.get_zero_to_many_source_radio
          when "1m"
            radio = propertyDialog.get_one_to_many_source_radio
          when "01"
            radio = propertyDialog.get_zero_to_one_source_radio
          when "11"
            radio = propertyDialog.get_one_to_one_source_radio
        end
        propertyDialog.radioGroupSource.set_selected radio.get_model, true

        #Selects radio button based on target point
        case targetType
          when "0m"
            radio = propertyDialog.get_zero_to_many_target_radio
          when "1m"
            radio = propertyDialog.get_one_to_many_target_radio
          when "01"
            radio = propertyDialog.get_zero_to_one_target_radio
          when "11"
            radio = propertyDialog.get_one_to_one_target_radio
        end
        propertyDialog.radioGroupTarget.set_selected radio.get_model, true


        #Fills definition text area
        definition = connection.definition
        propertyDialog.get_definition_area.set_text definition

        propertyDialog.set_visible true

        #Processes dialog input if okButton was clicked
        if propertyDialog.closeAction == "ok"
          connection.name = propertyDialog.get_name_field.get_text
          connection.label.set_text connection.name
          connection.label.set_size connection.label.get_preferred_size

          connection.definition = propertyDialog.get_definition_area.get_text


          #Obtain selected source radio button
          options = propertyDialog.radioGroupSource.get_elements
          selected = (return_selected options).get_text

          case selected
            when "0,M"
              connection.sourceEP.type = "0m"
            when "1,M"
              connection.sourceEP.type = "1m"
            when "0,1"
              connection.sourceEP.type = "01"
            when "1,1"
              connection.sourceEP.type = "11"
          end

          #Obtain selected target radio button
          options = propertyDialog.radioGroupTarget.get_elements
          selected = (return_selected options).get_text

          case selected
            when "0,M"
              connection.targetEP.type = "0m"
            when "1,M"
              connection.targetEP.type = "1m"
            when "0,1"
              connection.targetEP.type = "01"
            when "1,1"
              connection.targetEP.type = "11"
          end



          parent.panel.repaint
        end
      end



    end
  end


  def mousePressed e
    source = e.source
    parent = (SwingUtilities.getWindowAncestor source)

    if parent.drawType == "connection"  && source.class.to_s == "Entity"
      puts source.name
      @@pressedSource = source
      border = BorderFactory.create_line_border Color::green, 2
      source.set_border border


    end
  end

  def mouseEntered e
    source = e.source
    #puts "Pressed" + @@pressedSource.class.to_s
    parent = (SwingUtilities.getWindowAncestor source)

    if parent.drawType == "connection" && !@@pressedSource.nil?  && source.class.to_s == "Entity"
      puts @@pressedSource.name
      if !source.equal? @@pressedSource && !@@pressedSource.nil?

        border = BorderFactory.create_line_border Color::green, 2
        source.set_border border
        pressedEntity = @@pressedSource
        sourcePoint = Point2D::Double.new pressedEntity.get_x + 55, pressedEntity.get_y + 30
        targetPoint = Point2D::Double.new source.get_x + 55, source.get_y + 30
        #puts "Before adding " + @@pressedSource.class.to_s

        if SHOW_CONNECTION_DIALOG

          propertyDialog = parent.connectionDialog
          propertyDialog.closeAction = "cancel"

          propertyDialog.get_name_field.set_text "untitled"

          propertyDialog.get_source_label.set_text "["+ pressedEntity.name + "]"
          propertyDialog.get_target_label.set_text "["+ source.name + "]"



          radio = propertyDialog.get_zero_to_many_source_radio
          propertyDialog.radioGroupSource.set_selected radio.get_model, true

          radio = propertyDialog.get_zero_to_many_target_radio
          propertyDialog.radioGroupTarget.set_selected radio.get_model, true



          #Fills definition text area
          definition = "fill later ..."
          propertyDialog.get_definition_area.set_text definition

          propertyDialog.set_visible true

          if propertyDialog.closeAction == "ok"
            name = propertyDialog.get_name_field.get_text
            if name.empty? || name.nil?
              name = "untitled"
            end
            definition =  propertyDialog.get_definition_area.get_text
            if definition.empty? || definition.nil?
              definition = "fill later..."
            end

            #Obtain selected source radio button
            options = propertyDialog.radioGroupSource.get_elements
            selected = (return_selected options).get_text

            case selected
              when "0,M"
                sourceType = "0m"
              when "1,M"
                sourceType = "1m"
              when "0,1"
                sourceType = "01"
              when "1,1"
                sourceType = "11"
            end

            #Obtain selected target radio button
            options = propertyDialog.radioGroupTarget.get_elements
            selected = (return_selected options).get_text

            case selected
              when "0,M"
                targetType = "0m"
              when "1,M"
                targetType = "1m"
              when "0,1"
                targetType = "01"
              when "1,1"
                targetType = "11"
            end


            parent.add_connection @@pressedSource, source, sourcePoint, targetPoint, sourceType, targetType, name, definition
          end
        else
          parent.add_connection @@pressedSource, source, sourcePoint, targetPoint, "0m", "0m", "untitled", "none"
        end



        #puts "Added connection " + wtf.class.to_s

        border = BorderFactory.create_line_border Color::black
        source.set_border border
        #@@pressedSource.set_border border
        pressedEntity.set_border border
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

  def enable_buttons radioGroup
    radioGroup.get_elements.each do |button|
      button.set_enabled true
    end
  end

  def disable_buttons radioGroup, leaveEnabled
    radioGroup.get_elements.each do |button|
      button.set_enabled false unless button.get_text == leaveEnabled
    end
  end





end