#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/concerns/advantage_services_shared_context')
require_dependency "lti/ims/results_controller"

describe Lti::Ims::ResultsController do
  include_context 'advantage services context'

  let_once(:course) { course_factory(active_course: true) }
  let_once(:assignment) { assignment_model context: course}
  let_once(:result) { lti_result_model assignment: assignment }
  let(:json) { JSON.parse(response.body) }
  let(:params_overrides) do
    {
      course_id: course.id,
      line_item_id: result.lti_line_item_id
    }
  end

  describe '#index' do
    let(:action) { :index }

    before_once do
      8.times { lti_result_model line_item: result.line_item, assignment: assignment }
    end

    it 'returns a collection of results' do
      send_request
      expect(json.size).to eq 9
    end

    it 'formats the results correctly' do
      send_request
      expect { Lti::Result.find(json.first['id'].split('/').last.to_i) }.not_to raise_error
    end

    context 'with user_id in params' do
      let(:params_overrides) { super().merge(user_id: result.user_id) }

      it 'returns a single result' do
        send_request
        expect(json.size).to eq 1
      end

      it 'returns the user result' do
        send_request
        expect(json.first['userId'].to_i).to eq result.user_id
      end

      context 'with non-existent user' do
        let(:params_overrides) { super().merge(user_id: User.maximum(:id) + 1) }

        it 'returns an empty array' do
          send_request
          expect(json).to be_empty
        end
      end

      context 'with no result for user' do
        let(:params_overrides) { super().merge(user_id: create_users_in_course(course, 1, return_type: :record).first.id) }

        it 'returns an empty array' do
          send_request
          expect(json).to be_empty
        end
      end

      context 'with user not in course' do
        let(:params_overrides) { super().merge(user_id: student_in_course(course: course, active_all: true).user.id) }

        it 'returns empty array' do
          send_request
          expect(json).to be_empty
        end
      end

      context 'with user not a student' do
        let(:params_overrides) { super().merge(user_id: ta_in_course(course: course, active_all: true).user.id) }

        it 'returns empty array' do
          send_request
          expect(json).to be_empty
        end
      end
    end

    context 'with limit in params' do
      let(:params_overrides) { super().merge(limit: 2) }

      it 'honors the limit' do
        send_request
        expect(json.size).to eq 2
      end

      it 'provides the pagination headers' do
        send_request
        expect(response.headers['Link']).to include 'rel="next"'
      end
    end
  end

  describe '#show' do
    let(:params_overrides) { super().merge(id: result.id) }
    let(:action) { :show }

    it 'returns the result' do
      send_request
      expect(response).to have_http_status :ok
    end

    it 'formats the result correctly' do
      send_request
      rslt = Lti::Result.find(json['id'].split('/').last.to_i)
      expect(rslt).to eq result
    end

    context 'when result requested not in line_item' do
      let(:params_overrides) { super().merge(id: result.id, line_item_id: line_item_model(assignment: assignment).id) }

      it 'returns a 404' do
        send_request
        expect(response).to have_http_status :not_found
      end
    end

    context 'when result does not exist' do
      let(:params_overrides) { super().merge(id: result.id + 1) }

      it 'returns a 404' do
        send_request
        expect(response).to have_http_status :not_found
      end
    end
  end
end
