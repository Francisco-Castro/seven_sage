defmodule SevenSageWeb.RecordsLive do
  use SevenSageWeb, :live_view
  alias SevenSage.Records

  def mount(_params, _session, socket) do
    records = Records.all()
    {:ok, assign(socket, records: records)}
  end

  def render(assigns) do
    ~H"""
    <div>
      DASHBOARD
    </div>
    <div class="relative overflow-x-auto shadow-md sm:rounded-lg">
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
            class="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600"
          >
            <th
              scope="row"
              class="px-6 py-4 font-medium text-gray-900 whitespace-nowrap dark:text-white"
            >
              <%= record.rank %>
            </th>
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
    """
  end
end
