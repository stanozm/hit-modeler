include Java

import java.awt.event.MouseAdapter
import javax.swing.SwingUtilities

# Author::    Stanislav Chren (mailto:stanislavch@gmail.com)
# Copyright:: Copyright (c) 2012
# License::   GPL-3.0
#
# This class can be used as a listener which recomputes endpoint's position after it has been moved
# by dragging. It doesn't register event when endpoint's position changed by dragging its parent entity
class EndpointMouseAction < MouseAdapter

  def mouseReleased e
    source = e.get_source
    parent = SwingUtilities.getWindowAncestor source
    source.reset_direction
    source.reset_position
    parent.panel.repaint
  end
end