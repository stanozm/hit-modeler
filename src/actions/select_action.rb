include Java

import java.awt.event.MouseAdapter
import javax.swing.SwingUtilities
import javax.swing.BorderFactory
import java.awt.Color
import java.awt.BasicStroke

# Author::    Stanislav Chren (mailto:stanislavch@gmail.com)
# Copyright:: Copyright (c) 2012
# License::   GPL-3.0
#
# This class can be used as a listener which detects mouse clicks on entities and endpoints.
# If one click is registered, component is selected, which means deselecting previously selected. Selection
# visualised by painting itself or its borders blue.
# If two double-click is detected, the property dialog of the clicked component is shown and afterward its contents
# processed
# Moreover, if main window's attribute draw_type is set to "connection", behaviour is different:
# * pressed mouse on entity is detected. This entity becomes source entity
# * if mouse is moved and still pressed, when it enters boundary of another entity, this entity is marked as target.
# * connection between marked entities is created. Source points for endpoints are set as points in the middle
#   of marked entities
# Self-referencing connections are not supported at this moment
# TODO: add self-referencing connections support
class SelectAction < MouseAdapter

  # if set to false, default connection between entities is created, without displaying property dialog
  SHOW_CONNECTION_DIALOG = true

  def initialize modeler
    super()
    @modeler = modeler
    @@pressed_source = nil
  end

  def mouseClicked e
    #Component which the mouse clicked on
    source = e.source

    click_count = e.getClickCount

    #Main frame
    parent = (SwingUtilities.getWindowAncestor source)

    #Previous focus
    focus = parent.focus
    focus_class = focus.class.to_s

    if parent.draw_type == "pointer"

      #Deselects previously selected entity
      if (!focus.nil?)  && (focus_class == "Entity")
        border = BorderFactory.create_line_border Color::black,1
        parent.focus.set_border border
        parent.panel.repaint
      end

      #Deselects previously selescted connectin
      if (!focus.nil?)  && (focus_class == "Connection")

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
        @modeler.display_definition source.definition
      end

      #Sets focus on connection of the currently selected endpoint
      if source.class.to_s == "Endpoint"
        focus_connection = source.connection
        focus_connection.color = Color::blue
        focus_connection.stroke = BasicStroke.new 2
        focus_connection.label.set_foreground Color::blue
        parent.focus = focus_connection
        @modeler.display_definition focus_connection.definition
      end

      parent.panel.repaint
      #double-click

      if click_count == 2 && source.class.to_s == "Entity"

        #Obtain entity properties dialog
        property_dialog = parent.entity_dialog
        property_dialog.close_action = "cancel"

        property_dialog.get_name_field.set_text source.name

        type = source.type

        #Selects radio button based on selected entity
        case type
          when "kernel"
            radio = property_dialog.get_kernel_radio
          when "associative"
            radio = property_dialog.get_associative_radio
          when "descriptive"
            radio = property_dialog.get_descriptive_radio
        end
        property_dialog.radio_group.set_selected radio.get_model, true

        #Fills definition text area
        definition = source.definition
        property_dialog.get_definition_area.set_text definition

        property_dialog.set_visible true

        #Processes dialog input if okButton was clicked
        if property_dialog.close_action == "ok"
          source.name = property_dialog.get_name_field.get_text
          source.definition = property_dialog.get_definition_area.get_text
          source.set_tool_tip_text definition

          #Obtain selected radio button
          options = property_dialog.radio_group.get_elements
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
      if click_count == 2 && source.class.to_s == "Endpoint"

        connection = source.connection

        #Obtain entity properties dialog
        property_dialog = parent.connection_dialog
        property_dialog.close_action = "cancel"

        property_dialog.get_name_field.set_text connection.name

        property_dialog.get_source_label.set_text "["+ connection.source_ep.entity_parent.name + "]"
        property_dialog.get_target_label.set_text "["+ connection.target_ep.entity_parent.name + "]"

        source_type = connection.source_ep.type
        target_type = connection.target_ep.type

        #Selects radio button based on source point
        case source_type
          when "0m"
            radio = property_dialog.get_zero_to_many_source_radio
          when "1m"
            radio = property_dialog.get_one_to_many_source_radio
          when "01"
            radio = property_dialog.get_zero_to_one_source_radio
          when "11"
            radio = property_dialog.get_one_to_one_source_radio
        end
        property_dialog.radio_group_source.set_selected radio.get_model, true

        #Selects radio button based on target point
        case target_type
          when "0m"
            radio = property_dialog.get_zero_to_many_target_radio
          when "1m"
            radio = property_dialog.get_one_to_many_target_radio
          when "01"
            radio = property_dialog.get_zero_to_one_target_radio
          when "11"
            radio = property_dialog.get_one_to_one_target_radio
        end
        property_dialog.radio_group_target.set_selected radio.get_model, true


        #Fills definition text area
        definition = connection.definition
        property_dialog.get_definition_area.set_text definition

        property_dialog.set_visible true

        #Processes dialog input if okButton was clicked
        if property_dialog.close_action == "ok"
          connection.name = property_dialog.get_name_field.get_text
          connection.label.set_text connection.name
          connection.label.set_size connection.label.get_preferred_size

          connection.definition = property_dialog.get_definition_area.get_text


          #Obtain selected source radio button
          options = property_dialog.radio_group_source.get_elements
          selected = (return_selected options).get_text

          case selected
            when "0,M"
              connection.source_ep.type = "0m"
            when "1,M"
              connection.source_ep.type = "1m"
            when "0,1"
              connection.source_ep.type = "01"
            when "1,1"
              connection.source_ep.type = "11"
          end

          #Obtain selected target radio button
          options = property_dialog.radio_group_target.get_elements
          selected = (return_selected options).get_text

          case selected
            when "0,M"
              connection.target_ep.type = "0m"
            when "1,M"
              connection.target_ep.type = "1m"
            when "0,1"
              connection.target_ep.type = "01"
            when "1,1"
              connection.target_ep.type = "11"
          end
          parent.panel.repaint
        end
      end



    end
  end


  def mousePressed e
    source = e.source
    parent = (SwingUtilities.getWindowAncestor source)

    if parent.draw_type == "connection"  && source.class.to_s == "Entity"
      @@pressed_source = source
      border = BorderFactory.create_line_border Color::green, 2
      source.set_border border
    end
  end

  def mouseEntered e
    source = e.source
    parent = (SwingUtilities.getWindowAncestor source)

    if parent.draw_type == "connection" && !@@pressed_source.nil?  && source.class.to_s == "Entity"
      if !source.equal? @@pressed_source && !@@pressed_source.nil?

        border = BorderFactory.create_line_border Color::green, 2
        source.set_border border
        pressed_entity = @@pressed_source
        source_point = Point2D::Double.new pressed_entity.get_x + 55, pressed_entity.get_y + 30
        target_point = Point2D::Double.new source.get_x + 55, source.get_y + 30


        if SHOW_CONNECTION_DIALOG

          property_dialog = parent.connection_dialog
          property_dialog.close_action = "cancel"

          property_dialog.get_name_field.set_text ""

          property_dialog.get_source_label.set_text "["+ pressed_entity.name + "]"
          property_dialog.get_target_label.set_text "["+ source.name + "]"

          radio = property_dialog.get_zero_to_many_source_radio
          property_dialog.radio_group_source.set_selected radio.get_model, true

          radio = property_dialog.get_zero_to_many_target_radio
          property_dialog.radio_group_target.set_selected radio.get_model, true

          #Fills definition text area
          definition = "fill later ..."
          property_dialog.get_definition_area.set_text definition

          property_dialog.set_visible true

          if property_dialog.close_action == "ok"
            name = property_dialog.get_name_field.get_text
            if name.empty? || name.nil?
              name = ""
            end
            definition =  property_dialog.get_definition_area.get_text
            if definition.empty? || definition.nil?
              definition = "fill later..."
            end

            #Obtain selected source radio button
            options = property_dialog.radio_group_source.get_elements
            selected = (return_selected options).get_text

            case selected
              when "0,M"
                source_type = "0m"
              when "1,M"
                source_type = "1m"
              when "0,1"
                source_type = "01"
              when "1,1"
                source_type = "11"
            end

            #Obtain selected target radio button
            options = property_dialog.radio_group_target.get_elements
            selected = (return_selected options).get_text

            case selected
              when "0,M"
                target_type = "0m"
              when "1,M"
                target_type = "1m"
              when "0,1"
                target_type = "01"
              when "1,1"
                target_type = "11"
            end

            parent.add_connection @@pressed_source, source, source_point, target_point, source_type, target_type, name, definition
          end
        else
          parent.add_connection @@pressed_source, source, source_point, target_point, "0m", "0m", "untitled", "none"
        end

        border = BorderFactory.create_line_border Color::black
        source.set_border border
        pressed_entity.set_border border
        @@pressed_source = nil
        parent.panel.repaint
      end
    end

  end

  # Returns selected option from radio button group
  def return_selected options
    options.each do |option|
      return option if option.is_selected
    end
  end

  # Enables all disabled buttons in given button group
  def enable_buttons radio_group
    radio_group.get_elements.each do |button|
      button.set_enabled true
    end
  end

  # Disables all buttons besides specified one in given button group
  def disable_buttons radio_group, leave_enabled
    radio_group.get_elements.each do |button|
      button.set_enabled false unless button.get_text == leave_enabled
    end
  end
end