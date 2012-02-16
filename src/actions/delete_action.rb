include Java
import javax.swing.AbstractAction
import javax.swing.SwingUtilities

#Deletes selected entity and clears focus
class DeleteAction < AbstractAction
  def actionPerformed e

    source = e.source
    parent = SwingUtilities.getWindowAncestor source
    focus = parent.focus

    if !focus.nil?
      if focus.class.to_s == "Entity"

        connections = parent.connections
        endpoints = focus.endpoints

        marked = connections.select { |c| (endpoints.include? c.sourceEP) || (endpoints.include? c.targetEP) }
        marked.each do |c|
          sourceEP = c.sourceEP
          targetEP = c.targetEP

          sourceEP.entityParent.endpoints.delete sourceEP
          targetEP.entityParent.endpoints.delete targetEP

          source.remove sourceEP
          source.remove targetEP

          connections.delete c
        end

        source.remove focus
        source.revalidate
        focus = nil
        source.repaint
      end
    end

    puts e.source
    puts "mazem"
  end
end