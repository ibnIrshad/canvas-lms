#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

class AddUserIdToConversationMessageParticipants < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_column :conversation_message_participants, :user_id, :integer, :limit => 8
    add_index :conversation_message_participants, [:user_id, :conversation_message_id], :name => "index_conversation_message_participants_on_uid_and_message_id", :unique => true, :algorithm => :concurrently
  end

  def self.down
    remove_index :conversation_message_participants, [:user_id, :conversation_message_id]
    remove_column :conversation_message_participants, :user_id
  end
end
