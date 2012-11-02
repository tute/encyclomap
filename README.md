http://wikimapia.org/api/#Box

Wikimapia API keys:
  localhost = C0365FB4-18F780A5-0A8C5B5B-364CF187-0C128B10-9F6A2A88-D4187C26-EAD8434B
  localhost:4567 = C0365FB4-6B9AAA6F-9816D3DE-1ABEA4F3-D50712FD-A634D22B-25FA389F-5608B539


# On localStorage:
var testObject = { 'one': 1, 'two': 2, 'three': 3 };

// Put the object into storage
localStorage.setItem('testObject', JSON.stringify(testObject));

// Retrieve the object from storage
var retrievedObject = localStorage.getItem('testObject');

console.log('retrievedObject: ', JSON.parse(retrievedObject));
