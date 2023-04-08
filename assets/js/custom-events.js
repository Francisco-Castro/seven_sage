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

  if (result < 0) {
    position_msg = `${abs_result} point${abs_result == 1 ? "" : "s"} below the median`
  } else if (result > 0) {
    position_msg = `${result} point${abs_result == 1 ? "" : "s"} above the median`
  } else {
    position_msg = `exactly at the median`
  }

  p.innerHTML = `Ranked #${rank.innerHTML.trim()} in ${year.innerHTML}. With your ${student_score} points, you are ${position_msg}.`
});