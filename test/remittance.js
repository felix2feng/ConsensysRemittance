var Remittance = artifacts.require("./Remittance.sol");

contract('Remittance', function(accounts) {
  var remittanceInstance;
  var password1 = 'hello';
  var password2 = 'world';

  var hashOfPassword1, hashOfPassword2;
  var passCode;

  beforeEach(function() {
    return Remittance.deployed().then(function(instance) {
      remittanceInstance = instance;
      return Promise.all([
        instance.hashSingleInput.call(password1), 
        instance.hashSingleInput.call(password2)
      ]);
    }).then(function(promiseObj) {
      hashOfPassword1 = promiseObj[0];
      hashOfPassword2 = promiseObj[1];
      return remittanceInstance.hashTwoInputs.call(hashOfPassword1, hashOfPassword2);
    }).then(function (hashOfTwoInputs) {
      passCode = hashOfTwoInputs;
    });
  });

  it('should register a remittance', function () {
    return remittanceInstance.deposit(passCode, 5000, { from: accounts[0], value: 100 })
      .then(function () {
        return remittanceInstance.remittances(passCode.toString());
      }).then(function (remittanceObj) {
        assert.equal(remittanceObj[1], 100, "The value should be 100");
      });
  });

  // TODO - Current test fails. How would one debug better? Seems you can't console log
  // it('should allow one to withdraw with the correct passcode', function () {
  //   return remittanceInstance.withdraw(hashOfPassword1, hashOfPassword2, { from: accounts[1] })
  //     .then(function () {
  //       return remittanceInstance.remittances(passCode.toString());  
  //     })
  //     .then(function (remittanceObj) {
  //       assert.equal(remittanceObj[1], 0, "The value should be 0");
  //     });
  // });

});
