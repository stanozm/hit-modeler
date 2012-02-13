include Java

java_import 'EDialog'
import javax.swing.JFrame
import java.awt.Dimension
import javax.swing.ButtonGroup

class EntityDialog  < EDialog

  attr_accessor :closeAction, :radioGroup

  def initialize parent, modal
    super parent, modal
    self.set_location_relative_to parent

    self.initDialog

  end

  def initDialog

    @radioGroup = ButtonGroup.new
    [self.get_kernel_radio,self.get_associative_radio,self.get_descriptive_radio].each{ |c| @radioGroup.add c}

    self.get_ok_button.add_action_listener do |e|
      @closeAction = "ok"
      self.set_visible false
    end

    self.get_cancel_button.add_action_listener do |e|
      @closeAction = "cancel"
      self.set_visible false
    end
  end
end


