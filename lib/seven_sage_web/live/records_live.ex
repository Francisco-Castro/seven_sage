defmodule SevenSageWeb.RecordsLive do
  use SevenSageWeb, :live_view
  alias SevenSage.Records
  alias SevenSage.Accounts
  alias Phoenix.LiveView.JS

  def mount(_params, session, socket) do
    %{"student_token" => token} = session
    student = Accounts.get_student_by_session_token(token)

    records = Records.list_records()

    socket =
      assign(socket,
        student: student,
        records: records
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
        <%= for {{label, atom}, index} <- Enum.with_index([{"ALL", ""} ,{"≤ L25", :L25}, {"≤ L50", :L50}, {"≤ L75", :L75}]) do %>
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
    <div
      phx-click-away={JS.hide(to: "#card-info")}
      class="relative overflow-x-auto shadow-md sm:rounded-lg"
    >
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
    <script>
      window.addEventListener("click_on_record", e => {
        const dispatcher = e.detail.dispatcher;
        const tds = dispatcher.getElementsByTagName('td');

        [rank, school_name, year, l75, l50, l25] = tds

        const card_info = document.getElementById('card-info')

        card_info.style.display = 'block'

        const h5 = card_info.getElementsByTagName('h5')[0]
        h5.innerHTML = school_name.innerHTML

        const student_score = Number(document.getElementById('student_score').innerHTML)

        const p = card_info.getElementsByTagName('p')[0]

        const result = student_score - Number(l50.innerHTML)
        const abs_result = Math.abs(result)

        if(result < 0) {
          position_msg = `${abs_result} point${abs_result == 1 ? "" : "s"} below the median`
        } else if (result > 0 ) {
          position_msg = `${result} point${abs_result == 1 ? "" : "s"} above the median`
        } else {
          position_msg = `exactly at the median`
        }

        p.innerHTML = `Ranked #${rank.innerHTML.trim()} in ${year.innerHTML}. With your ${student_score} points, you are ${position_msg}.`
          });
    </script>
    """
  end

  def handle_event("filter", %{"value" => percentile}, socket) do
    lsat_score = socket.assigns.student.lsat_score

    records = Records.list_records(percentile, lsat_score)

    socket = assign(socket, records: records)

    {:noreply, socket}
  end

  defp rounded_by(0), do: "rounded-l-lg"
  defp rounded_by(3), do: "rounded-r-md"
  defp rounded_by(_), do: "border-t border-b"
end
