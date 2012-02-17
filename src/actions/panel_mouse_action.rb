include Java

import java.awt.event.MouseAdapter
import javax.swing.SwingUtilities
import javax.swing.JOptionPane

class PanelMouseAction < MouseAdapter

  def mouseReleased e

    source = e.source
    x = e.getX
    y = e.getY

    parent = (SwingUtilities.getWindowAncestor source)
    type = parent.draw_type



    if ["kernel","associative","descriptive"].include? type

      name = JOptionPane.showInputDialog parent, "Enter name:", "New entity", JOptionPane::PLAIN_MESSAGE, nil, nil, "untitled"

      if  !name.nil? && !name.empty?
       ent = parent.add_entity name, type, nil, x-55, y-30
       ent.id = parent.max_id
       parent.max_id = parent.max_id + 1
      puts ent.id.to_s
      end
    end
  end
end