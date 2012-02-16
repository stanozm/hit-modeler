include Java

java_import 'CDialog'

import javax.swing.ButtonGroup
import javax.swing.JFrame

class ConnectionDialog < CDialog

  attr_accessor :closeAction, :radioGroupSource, :radioGroupTarget

  def initialize parent, modal
    super parent, modal
    self.set_location_relative_to parent

    self.initDialog

  end

  def initDialog
    @radioGroupSource = ButtonGroup.new
    [self.get_zero_to_many_source_radio,
     self.get_one_to_many_source_radio,
     self.get_zero_to_one_source_radio,
     self.get_one_to_one_source_radio].each {|c| @radioGroupSource.add c}

    @radioGroupTarget = ButtonGroup.new
    [self.get_zero_to_many_target_radio,
     self.get_one_to_many_target_radio,
     self.get_zero_to_one_target_radio,
     self.get_one_to_one_target_radio].each {|c| @radioGroupTarget.add c}

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
