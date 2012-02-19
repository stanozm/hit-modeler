include Java

import java.awt.event.ComponentAdapter
import javax.swing.SwingUtilities

# Author::    Stanislav Chren (mailto:stanislavch@gmail.com)
# Copyright:: Copyright (c) 2012
# License::   GPL-3.0
#
# This class can be used as a listener which detects movement of entity and ensures that all its children endpoints
# are moved with it as well. Endpoint's relative position to its parent doesn't change
class MoveAction < ComponentAdapter

  def componentMoved e
    source = e.get_component
    parent = SwingUtilities.getWindowAncestor source
    source_class = source.class.to_s

    if source_class == "Entity"
      source.endpoints.each do |ep|
        ep.reset_position
        ep.connection.reset_label_position
      end
    end
    parent.panel.repaint
  end
end