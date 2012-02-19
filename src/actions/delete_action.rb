include Java
import javax.swing.AbstractAction
import javax.swing.SwingUtilities

# Author::    Stanislav Chren (mailto:stanislavch@gmail.com)
# Copyright:: Copyright (c) 2012
# License::   GPL-3.0
#
# This class can be used as a listener which performes deleting selected entities or connections.
# Selection is determined by value of focus attribute of the main window.
class DeleteAction < AbstractAction
  def actionPerformed e

    source = e.source
    parent = SwingUtilities.getWindowAncestor source      #main window
    focus = parent.focus

    if !focus.nil?
      if focus.class.to_s == "Entity"

        #All connections
        connections = parent.connections
        #Endpoints belonging to focused entity
        endpoints = focus.endpoints
        #connections which contain endpoints on selected entity
        marked = []
        endpoints.each{ |ep| marked << ep.connection}

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
      end



    end

  end
end