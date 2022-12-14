function doPost(e)
{
  // Функция получает сигнал от бота
  var update = JSON.parse(e.postData.contents);
  // Объявлем все нужные нам переменные. Док важно открывать именно по ID, а не брать активный док, т.к. запуск кода будет производить бот
  var DOC = SpreadsheetApp.openById("1SOt9ng7UZ3oK6fKXYRPalU520Z2Fxh0_M30z3i0iiXA");
  var Clients = DOC.getSheetByName("Clients");
  var Calendar = DOC.getSheetByName("Calendar");
  // Проверяем - является ли сообщение - текстовым сообщением
  if (update.hasOwnProperty('message'))
  {
    // Дообявляем переменные связанные с сообщением
    var msg = update.message;
    var chat_id = msg.chat.id;
    var text = msg.text;
    var msg_array = msg.text.split(" ");
    var date = (msg.date/86400)+25569.125;
    var user = msg.from.username;
    // по Чат ИД получаем номер строки с листа Clients, функция внизу
    var user_row = userid(chat_id, user);
    var statement = Clients.getRange(user_row, 3).getValue();
    // прежде всего ставим проверку на Отмену, т.к. нужно дать возможность вызывать ее из любой части переписки.
    if (msg_array[0] == "Отмена")
    {
      Clients.getRange(user_row, 3).setValue("");
      send("Запись отменена", chat_id);
    }
    else
    {
      // Если это не отмена - начинаем работать со стейтментом.
      switch (statement) {
        case ""      : 
          {
            //Стартер нашей переписки - команда Записаться
            if (msg_array[0] == "Записаться")
            {
              send("Привет, @"+user+", на какую дату хочешь записаться?", chat_id);
              Clients.getRange(user_row, 3).setValue("Dates");
            }
            else
            {
              send("Прости, @"+user+", я не знаю такой команды =(. Для записи на прием используй команду Записаться", chat_id);
            }
            break;
          }
        case "Dates" :
          {
            // Первым делом проверяем есть ли уже такая дата в нашем календаре
            if (Calendar.getLastRow() == 1)
            {
              Calendar.appendRow([text]);
              send("День полностью свбоден. На какое время хочешь записаться?", chat_id);
              Clients.getRange(user_row, 3).setValue(text);
            }
            else
            {
              var date_row = 0;
              for (var i = 2; i <= Calendar.getLastRow(); i++)
              {
                if (text == Calendar.getRange(i, 1).getValue())
                {
                  date_row = i;
                  break;
                }
              }
              if (date_row == 0)
              {
                Calendar.appendRow([text]);
                date_row = Calendar.getLastRow();
              }
              // Если день уже существует - собираем свободные окна времени, пакуем их в одно сообщение и отправляем юзеру
              var message = "Свободные окна:";
              for (var j = 2; j<=17; j++)
              {
                if (Calendar.getRange(date_row, j).getValue() == "" && Calendar.getRange(date_row, j+1).getValue() == "" && Calendar.getRange(date_row, j+2).getValue() == "")
                {
                  message = message + "\n" + Calendar.getRange(1, j).getValue();
                }
              }
              send(message, chat_id);
              Clients.getRange(user_row, 3).setValue(text);
              break;
            }
            
            break;
          }
        default      : 
          {
            //Дефолт обрабатыает все прочие стейтменты, кроме указанных выше. Нам удобно, т.к. финальным стейтментом у нас выступает дата введенная пользователем
            //Находим дату, находим время и заполняем единичками время и две клетки справа
            for (var i = 2; i <= Calendar.getLastRow(); i++)
            {
              if (statement == Calendar.getRange(i, 1).getValue())
              {
                date_row = i;
                break;
              }
            }
            for (var j = 2; j <= 17; j++)
            {
              if (text == Calendar.getRange(1, j).getValue())
              {
                Calendar.getRange(date_row, j).setValue(1);
                Calendar.getRange(date_row, j+1).setValue(1);
                Calendar.getRange(date_row, j+2).setValue(1);
                break;
              }
            }
            send("Успешно записан на "+statement+" "+text, chat_id);
            Clients.getRange(user_row, 3).setValue("");
          }
      }
    }
  }
}
function send (msg, chat_id)
{
  //Отправляет сообщения в тлг. На вход функции дать сообщение и ID чата, в который нужно провести отправку
  var payload = {
    'method': 'sendMessage',
    'chat_id': String(chat_id),
    'text': msg,
    'parse_mode': 'HTML'
  }
  var data = {
    "method": "post",
    "payload": payload
  }
  var API_TOKEN = '1176495029:AAGuzwgHDAYCBhLsK7p7qUU5Pk2EK4kax9I'
  UrlFetchApp.fetch('https://api.telegram.org/bot' + API_TOKEN + '/', data);
}

function userid (chatid, user)
{
  // По ИД чата находит строчку, в которой записан наш пользователь
  var DOC = SpreadsheetApp.openById("1SOt9ng7UZ3oK6fKXYRPalU520Z2Fxh0_M30z3i0iiXA");
  var Clients = DOC.getSheetByName("Clients");
  var lr = Clients.getLastRow();
  var user_id = 0;
  if (lr == 1)
  {
    Clients.appendRow([user, chatid]);
    return lr+1;
  }
  else
  {
    for (var i = 1; i <= lr; i++)
    {
      if (Clients.getRange(i, 2).getValue() == chatid)
      {
        user_id = i;
        return user_id;
        break;
      }
    }
    if (user_id = 0)
    {
      Clients.appendRow([user, chatid]);
      return lr+1;
    }
