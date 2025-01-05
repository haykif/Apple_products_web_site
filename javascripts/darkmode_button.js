function addDarkmodeWidget() {
    const options = {
        bottom: '32px', // default: '32px'
        right: '32px', // default: '32px'
        left: 'unset', // default: 'unset'
        time: '1s', // default: '0.3s'
        mixColor: '#fff', // default: '#fff'
        backgroundColor: '#f2f2f2',  // default: '#fff'
        buttonColorDark: '#100f2c',  // default: '#100f2c'
        buttonColorLight: '#FFFFFF', // default: '#fff'
        saveInCookies: false, // default: true,
        label: '🌙', // default: ''
        autoMatchOsTheme: true // default: true
    }
    const darkmode = new Darkmode(options);
    darkmode.showWidget();
}
window.addEventListener('load', addDarkmodeWidget);