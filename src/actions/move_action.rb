include Java

import java.awt.event.ComponentAdapter
import javax.swing.SwingUtilities

class MoveAction < ComponentAdapter

  def componentMoved e

    source = e.get_component
    parent = SwingUtilities.getWindowAncestor source


    sourceClass = source.class.to_s

    if sourceClass == "Entity"

      source.endpoints.each{ |ep| ep.reset_position}
    end

    parent.panel.repaint

  end
end