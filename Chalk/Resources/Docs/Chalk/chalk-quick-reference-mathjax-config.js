function configureMathJax()
{
  window.MathJax = {
    options: {
      renderActions: {
        addMenu: [],
        checkLoading: []
      },
      ignoreHtmlClass: 'tex2jax_ignore',
      processHtmlClass: 'tex2jax_process'
    },
    startup: {
      typeset: true,
      ready: () => {
        window.MathJax.startup.defaultReady();
      }
    },
    compileError: function (doc, math, err) {
      console.log('compile:'+'doc'+'<'+doc+'>'+'math'+'<'+math+'>'+'err'+'<'+err+'>');
    },
    typesetError: function (doc, math, err) {
      console.log('typeset:'+'doc'+'<'+doc+'>'+'math'+'<'+math+'>'+'err'+'<'+err+'>');
    }
  };
}
//end configureMathJax()

configureMathJax();
