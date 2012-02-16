include Java

import java.awt.event.MouseAdapter
import javax.swing.SwingUtilities

class EndpointMouseAction < MouseAdapter



  def mouseReleased e
    source = e.get_source
    parent = SwingUtilities.getWindowAncestor source
    source.reset_direction
    source.reset_position

    #source.connection.reset_label_position

    parent.panel.repaint


  end
end