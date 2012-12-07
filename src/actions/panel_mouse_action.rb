include Java

import java.awt.event.MouseAdapter
import javax.swing.SwingUtilities
import javax.swing.JOptionPane
import java.awt.Color
import javax.swing.BorderFactory
import java.awt.BasicStroke

# Author::    Stanislav Chren (mailto:stanislavch@gmail.com)
# Copyright:: Copyright (c) 2012
# License::   GPL-3.0
#
# This class can be used as a listener which detects mouse clicks on panel. Following action depends on draw_type
# attribute of main window. It will either create enitiy of specified type or deselects any currently selected object
class PanelMouseAction < MouseAdapter

  def initialize modeler
    super()
    @modeler = modeler
  end

  def mouseReleased e
    @modeler.clear_displayed_definition        

    source = e.source
    x = e.getX
    y = e.getY

    parent = (SwingUtilities.getWindowAncestor source)
    type = parent.draw_type

     case type
       when "kernel", "associative", "descriptive"
          name = JOptionPane.showInputDialog parent, "Enter name:", "New entity", JOptionPane::PLAIN_MESSAGE, nil, nil, "untitled"
          if  !name.nil? && !name.empty?
            ent = parent.add_entity name, type, nil, x-55, y-30
            ent.id = parent.max_id
            parent.max_id = parent.max_id + 1
          end

       when "pointer"
         focus = parent.focus
         focus_class = focus.class.to_s
         case focus_class
           when "Entity"
             border = BorderFactory.create_line_border Color::black,1
             parent.focus.set_border border
             parent.panel.repaint
             parent.focus = nil
           when "Connection"
             parent.focus.color = Color::black
             parent.focus.stroke = BasicStroke.new 1
             parent.focus.label.set_foreground Color::black
             parent.panel.repaint
             parent.focus = nil
         end

    end
  end
end