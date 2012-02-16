include Java

import java.awt.event.ComponentAdapter
import javax.swing.SwingUtilities

class MoveAction < ComponentAdapter

  def componentMoved e

    source = e.get_component
    parent = SwingUtilities.getWindowAncestor source


    sourceClass = source.class.to_s

    if sourceClass == "Entity"

      source.endpoints.each do |ep|
        ep.reset_position
        ep.connection.reset_label_position
      end
    end

    parent.panel.repaint

  end
end