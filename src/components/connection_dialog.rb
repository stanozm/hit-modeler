include Java

java_import 'CDialog'

import javax.swing.ButtonGroup
import javax.swing.JFrame

# Author::    Stanislav Chren (mailto:stanislavch@gmail.com)
# Copyright:: Copyright (c) 2012
# License::   GPL-3.0
#
# This class represents dialog for editiing connection properties
class ConnectionDialog < CDialog

  attr_accessor :close_action, :radio_group_source, :radio_group_target

  def initialize parent, modal
    super parent, modal
    self.set_location_relative_to parent

    self.init_dialog

  end

  def init_dialog
    @radio_group_source = ButtonGroup.new
    [self.get_zero_to_many_source_radio,
     self.get_one_to_many_source_radio,
     self.get_zero_to_one_source_radio,
     self.get_one_to_one_source_radio].each {|c| @radio_group_source.add c}

    @radio_group_target = ButtonGroup.new
    [self.get_zero_to_many_target_radio,
     self.get_one_to_many_target_radio,
     self.get_zero_to_one_target_radio,
     self.get_one_to_one_target_radio].each {|c| @radio_group_target.add c}

    self.get_ok_button.add_action_listener do |e|
      @close_action = "ok"
      self.set_visible false
    end

    self.get_cancel_button.add_action_listener do |e|
      @close_action = "cancel"
      self.set_visible false
    end


  end


end
