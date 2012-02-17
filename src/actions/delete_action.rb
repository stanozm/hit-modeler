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

        #marked = connections.select { |c| (endpoints.include? c.source_ep) || (endpoints.include? c.target_ep) }
        marked.each do |c|
          source_ep = c.source_ep
          target_ep = c.target_ep

          source_ep.entity_parent.endpoints.delete source_ep
          target_ep.entity_parent.endpoints.delete target_ep

          source.remove source_ep
          source.remove target_ep

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

        source_ep = connection.source_ep
        target_ep = connection.target_ep

        source_ep.entity_parent.endpoints.delete source_ep
        target_ep.entity_parent.endpoints.delete target_ep

        [source_ep,target_ep].each{ |e| source.remove e}

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