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
    type = parent.drawType

    if ["kernel","associative","descriptive"].include? type

      name = JOptionPane.showInputDialog parent, "Enter name:", "New entity", JOptionPane::PLAIN_MESSAGE, nil, nil, "untitled"

      if  !name.nil? && !name.empty?
        parent.add_entity name, type, nil, x, y
      end
    end
  end
end