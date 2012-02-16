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

        #All connections
        connections = parent.connections
        #Endpoints belonging to focused entity
        endpoints = focus.endpoints

        marked = []
        endpoints.each{ |ep| marked << ep.connection}

        #marked = connections.select { |c| (endpoints.include? c.sourceEP) || (endpoints.include? c.targetEP) }
        marked.each do |c|
          sourceEP = c.sourceEP
          targetEP = c.targetEP

          sourceEP.entityParent.endpoints.delete sourceEP
          targetEP.entityParent.endpoints.delete targetEP

          source.remove sourceEP
          source.remove targetEP

          source.remove c.label

          connections.delete c
        end

        parent.entities.delete focus
        source.remove focus
        source.revalidate
        focus = nil
        source.repaint
      end

      if focus.class.to_s == "Connection"

        connection = focus

        sourceEP = connection.sourceEP
        targetEP = connection.targetEP

        sourceEP.entityParent.endpoints.delete sourceEP
        targetEP.entityParent.endpoints.delete targetEP

        [sourceEP,targetEP].each{ |e| source.remove e}

        source.remove connection.label
        parent.connections.delete connection

        focus = nil
        source.revalidate
        source.repaint
        puts parent.connections
      end



    end

  end
end