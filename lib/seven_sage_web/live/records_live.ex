defmodule SevenSageWeb.RecordsLive do
  use SevenSageWeb, :live_view
  alias SevenSage.Records
  alias SevenSage.Accounts
  alias Phoenix.LiveView.JS

  def mount(_params, session, socket) do
    %{"student_token" => token} = session
    student = Accounts.get_student_by_session_token(token)

    records = Records.list_records()
    records_length = Records.count_records()

    socket =
      assign(socket,
        student: student,
        records: records,
        records_length: records_length
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-row justify-around py-10">
      <div class="text-2xl">
        <%= @student.name %>'s score is
        <span id="student_score" class="font-bold"><%= @student.lsat_score %></span>
      </div>
      <div class="flex flex-row items-center justify-center">
        <span class="mr-4">Filter by: </span>
        <%= for {{label, atom}, index} <- Enum.with_index([{"ALL", ""},{"≥ L75", :L75} ,{"≥ L50", :L50}, {"≥ L25", :L25}]) do %>
          <button
            phx-click="filter"
            value={atom}
            class={"#{rounded_by(index)} hover:cursor-pointer px-4 py-2 text-sm font-medium text-gray-900 bg-white border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:bg-gray-700 dark:border-gray-600 dark:text-white dark:hover:text-white dark:hover:bg-gray-600 dark:focus:ring-blue-500 dark:focus:text-white"}
          >
            <%= label %>
          </button>
        <% end %>
      </div>
    </div>
    <div :if={@records_length == 0} class="text text-center underline">No results</div>
    <div :if={@records_length > 0} class="relative">
      <div
        class="absolute rounded-full w-[40px] h-[40px] flex flex-col justify-center items-center text-white -translate-x-[16px] -translate-y-[16px] shadow-2xl"
        style="background-color: #AB0C2F;"
      >
        <span>
          <%= @records_length %>
        </span>
      </div>
      <div phx-click-away={JS.hide(to: "#card-info")} class="overflow-x-auto shadow-md sm:rounded-lg">
        <table class="text-center w-full text-sm text-gray-500 dark:text-gray-400">
          <thead class=" text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
            <tr>
              <th scope="col" class="px-6 py-3">
                RANK
              </th>
              <th scope="col" class="px-6 py-3">
                SCHOOL
              </th>
              <th scope="col" class="px-6 py-3">
                FIRST YEAR CLASS
              </th>
              <th scope="col" class="px-6 py-3">
                L75
              </th>
              <th scope="col" class="px-6 py-3">
                L50
              </th>
              <th scope="col" class="px-6 py-3">
                L25
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              :for={record <- @records}
              phx-click={JS.dispatch("click_on_record", to: "#card-info")}
              class="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600"
            >
              <td class="px-6 py-4">
                <%= record.rank %>
              </td>
              <td class="px-6 py-4">
                <%= record.school_name %>
              </td>
              <td class="tpx-6 py-4">
                <%= record.first_year_class %>
              </td>
              <td class="px-6 py-4">
                <%= Map.get(record, :L75) %>
              </td>
              <td class="px-6 py-4">
                <%= Map.get(record, :L50) %>
              </td>
              <td class="px-6 py-4">
                <%= Map.get(record, :L25) %>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  def handle_event("filter", %{"value" => percentile}, socket) do
    lsat_score = socket.assigns.student.lsat_score

    records = Records.list_records(percentile, lsat_score)
    records_length = Records.count_records(percentile, lsat_score)

    socket = assign(socket, records: records, records_length: records_length)

    {:noreply, socket}
  end

  defp rounded_by(0), do: "rounded-l-lg"
  defp rounded_by(3), do: "rounded-r-md"
  defp rounded_by(_), do: "border-t border-b"
end
